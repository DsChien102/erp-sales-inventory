# Sales refactor — Bảng 13 `sales.return_exchange_lines` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tính đúng `base_quantity_micros` của dòng đổi trả (nhân hệ số quy đổi, hàng đổi vào tra Catalog), ép dòng trả cùng sản phẩm/đơn vị với dòng nguồn, bỏ `pricing_snapshot`, `line_value_minor`, `line_note`, `updated_at`, dọn CHECK trùng và alter cũ — **sửa trực tiếp migration gốc**, không đổi Dart.

**Architecture:** Bảng ở `20260830005`. Hai helper mới đặt đầu `20260830012` (`_product_unit_conversion_rate`, `_base_quantity_micros`), dùng trong vòng lặp dòng của `start_return_exchange` và `update_return_exchange`. `evaluate_return_exchange_valuation` (`013`) bỏ nhánh đọc `pricing_snapshot`.

**Tech Stack:** PostgreSQL/Supabase plpgsql; Dart `package:test`.

**Spec:** [13-return-exchange-lines.md](../specs/sales-schema-refactor/13-return-exchange-lines.md) · Quy ước: [README §Quy ước implement](../specs/sales-schema-refactor/README.md#quy-ước-implement-sửa-trực-tiếp-migration-gốc)

## Global Constraints

- Tuân thủ **Quy ước implement**. Thứ tự: sau plan 12 (plan 1, 6, 12 đã sửa `start`/`update`) — tìm theo nội dung.
- Lỗi hệ số dùng đúng mã của checkout: `INVALID_QUANTITY` (hệ số thiếu/≤0, số lượng cơ sở lẻ/vượt phạm vi), `PRODUCT_NOT_SELLABLE` (hàng đổi vào không còn bán).
- Không sửa `finalize_sales_order`, không sửa Dart.
- Không `dart format` cả package; chỉ file test mới.
- **Không `git commit`** — cuối mỗi task tóm tắt + đề xuất commit rồi dừng.
- Trước khi sửa hàm: `node .gitnexus/run.cjs impact "<tên hàm>" --direction upstream --repo .` cho `start_return_exchange`, `update_return_exchange`, `evaluate_return_exchange_valuation` (hàm SQL → `UNKNOWN`; đối chiếu khảo sát).

## Khảo sát

| Vị trí | Nội dung |
|---|---|
| `20260830005` `create table if not exists sales.return_exchange_lines` | có `line_value_minor`, `pricing_snapshot`, `line_note`, `updated_at`, CHECK `return_exchange_lines_value_nonneg` |
| `20260830005` khối SCHEMA EVOLUTION | comment `-- ADR-9: exchanged-in goods …` + `alter … add column if not exists source_exchange_line_id uuid;` + khối `do $$ … end; $$;` (unique, drop check cũ, single_source, source_exchange_fk); cặp drop/add `return_exchange_lines_base_qty_positive`; cặp drop/add `return_exchange_lines_returned_source_xor` |
| `20260830012` `start_return_exchange` / `update_return_exchange` | `declare … v_qty bigint;`; nhánh `returned` lấy `v_unit_snapshot` từ `sales_order_lines.product_unit_snapshot` (đã có `conversionRateToBase`) hoặc từ dòng đổi nguồn; nhánh `exchange` lấy `v_unit_snapshot` từ `reference_decision` (không có hệ số); insert `… v_qty, v_qty, v_unit_price_minor, (v_unit_price_minor * v_qty) / 1000000, … jsonb_build_object('unitPriceMinor', …)` |
| `20260830013` `evaluate_return_exchange_valuation` | select `rl.unit_value_minor, rl.pricing_snapshot`; nhánh `if v_unit_price_minor is null and v_line.pricing_snapshot is not null and v_line.pricing_snapshot ? 'unit_price_minor' then … end if;` |
| `20260830008` `finalize_sales_order` | tra hệ số: `select pu.conversion_rate_to_base … from catalog.products p join catalog.product_units pu … p.business_status = 'active'::catalog.product_business_status and p.is_ready_to_sell = true … pu.is_active = true` — mẫu cho helper |
| Test | `returnable_exchange_source_schema_sql_contract_test.dart` chỉ kiểm tra tên cột/constraint còn trong `005` → vẫn pass |

## File Structure

| File | Thay đổi |
|---|---|
| Modify `supabase/migrations/20260830005_sales_rebuild_schema.sql` | `create table` + xoá alter/DO cũ |
| Modify `supabase/migrations/20260830012_sales_return_exchange_session_rpcs.sql` | 2 helper + header + 2 vòng lặp dòng |
| Modify `supabase/migrations/20260830013_sales_return_exchange_settlement_rpcs.sql` | bỏ nhánh `pricing_snapshot` |
| Create `modules/sales/infrastructure/test/domain/schema/sales_refactor_13_return_exchange_lines_sql_contract_test.dart` | SQL contract test |
| Modify `supabase/migrations/REGISTRY.yaml` | qua `seed_registry --write` |
| Modify `docs/superpowers/specs/sales-schema-refactor/README.md` | Tiến độ |

---

### Task 1: Bảng (`005`)

- [ ] **Step 1: Viết test (fail)**

```dart
import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Sales refactor bảng 13 `sales.return_exchange_lines`
/// (docs/superpowers/specs/sales-schema-refactor/13-return-exchange-lines.md).
void main() {
  final schemaSql = _readMigration('20260830005_sales_rebuild_schema.sql');
  const removed = ['line_value_minor', 'pricing_snapshot', 'line_note', 'updated_at'];

  test('return_exchange_lines drops dead columns and owns all checks', () {
    final start = schemaSql.indexOf(
      'create table if not exists sales.return_exchange_lines (',
    );
    final table = schemaSql.substring(start, schemaSql.indexOf('\n);', start));
    for (final column in removed) {
      expect(table, isNot(contains(column)), reason: column);
    }
    expect(table, contains('constraint return_exchange_lines_base_qty_positive'));
    expect(table, contains('constraint return_exchange_lines_unit_value_nonneg'));
    expect(table, contains('constraint return_exchange_lines_returned_single_source'));
    expect(schemaSql, isNot(contains('returned_source_xor')));
    expect(schemaSql, isNot(contains('alter table sales.return_exchange_lines')));
  });
}

String _readMigration(String fileName) {
  final root = _findRepoRoot();
  return File('${root.path}/supabase/migrations/$fileName').readAsStringSync();
}

/// Last `create or replace function <qualifiedName>(` … `$$;` in [sql].
String _lastFunctionBlock(String sql, String qualifiedName) {
  final start = sql.lastIndexOf('create or replace function $qualifiedName(');
  if (start < 0) {
    throw StateError('$qualifiedName not found');
  }
  final end = sql.indexOf(r'$$;', start);
  return sql.substring(start, end + 3);
}

Directory _findRepoRoot() {
  var current = Directory.current.absolute;
  while (!Directory('${current.path}/supabase/migrations').existsSync()) {
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not locate Vet45 workspace root');
    }
    current = parent;
  }
  return current;
}
```

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_13_return_exchange_lines_sql_contract_test.dart`
Expected: FAIL 1 test.

- [ ] **Step 3: Sửa `create table` trong `20260830005`** — thay cả khối bằng:

```sql
create table if not exists sales.return_exchange_lines (
  id uuid primary key,
  tenant_id uuid not null,
  return_exchange_order_id uuid not null,
  source_sales_order_id uuid not null,                                         -- denormalized source order (FC-12)
  line_sequence integer not null,
  line_role text not null,
  original_sales_order_line_id uuid,
  source_exchange_line_id uuid,                                                -- ADR-9: returnable exchange source
  product_id uuid not null,
  product_unit_id uuid not null,
  quantity_micros bigint not null,
  base_quantity_micros bigint not null,                                        -- quantity × product_unit_snapshot.conversionRateToBase
  unit_value_minor bigint not null,
  return_reason_code varchar(50),
  return_condition_code varchar(50),
  product_snapshot jsonb not null,
  product_unit_snapshot jsonb not null,
  created_at timestamptz not null default now(),
  constraint return_exchange_lines_seq_unique
    unique (return_exchange_order_id, line_sequence),
  constraint return_exchange_lines_tenant_id_unique unique (tenant_id, id),
  constraint return_exchange_lines_role_check check (line_role in ('returned', 'exchange')),
  constraint return_exchange_lines_qty_positive check (quantity_micros > 0),     -- FC-13
  constraint return_exchange_lines_base_qty_positive check (base_quantity_micros > 0),
  constraint return_exchange_lines_unit_value_nonneg check (unit_value_minor >= 0), -- FC-13
  -- ADR-9: a returned line references exactly one returnable unit
  -- (original order line XOR confirmed exchange line); exchange lines carry neither.
  constraint return_exchange_lines_returned_single_source check (
    (line_role = 'returned'
      and (original_sales_order_line_id is not null) <> (source_exchange_line_id is not null))
    or (line_role <> 'returned' and source_exchange_line_id is null)
  ),
  -- Parent + source order must match the operation's SalesOrder.
  constraint return_exchange_lines_parent_source_fk
    foreign key (tenant_id, return_exchange_order_id, source_sales_order_id)
    references sales.return_exchange_orders (tenant_id, id, sales_order_id)
    on delete cascade,                                                         -- FC-01
  -- FC-12: original line must belong to the RX source order (composite source key).
  constraint return_exchange_lines_original_source_order_fk
    foreign key (tenant_id, original_sales_order_line_id, source_sales_order_id)
    references sales.sales_order_lines (tenant_id, id, sales_order_id),
  constraint return_exchange_lines_source_exchange_fk
    foreign key (tenant_id, source_exchange_line_id)
    references sales.return_exchange_lines (tenant_id, id)
);
```

- [ ] **Step 4: Xoá alter/DO cũ trong SCHEMA EVOLUTION (`20260830005`)** — xoá 3 đoạn (kèm dòng trống theo sau mỗi đoạn):

1. Từ `-- ADR-9: exchanged-in goods are returnable — a returned line references either` tới hết khối `do $$ … end;` / `$$;` ngay sau đó (gồm `alter table sales.return_exchange_lines add column if not exists source_exchange_line_id uuid;`).
2. ```sql
   alter table sales.return_exchange_lines
     drop constraint if exists return_exchange_lines_base_qty_positive;
   alter table sales.return_exchange_lines
     add constraint return_exchange_lines_base_qty_positive
     check (base_quantity_micros > 0);
   ```
3. ```sql
   alter table sales.return_exchange_lines
     drop constraint if exists return_exchange_lines_returned_source_xor;
   alter table sales.return_exchange_lines
     add constraint return_exchange_lines_returned_source_xor
     check (
       line_role <> 'returned'
       or (
         (original_sales_order_line_id is not null)::integer
         + (source_exchange_line_id is not null)::integer = 1
       )
     );
   ```

- [ ] **Step 5: Chạy test, xác nhận pass**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_13_return_exchange_lines_sql_contract_test.dart test/domain/return_exchange_order/returnable_exchange_source_schema_sql_contract_test.dart test/domain/schema/sales_rebuild_schema_sql_contract_test.dart`
Expected: PASS.

- [ ] **Step 6: Tóm tắt + đề xuất commit, dừng chờ review**

Đề xuất: `refactor(sales): slim return/exchange lines table and fold legacy alters`

---

### Task 2: Tính đúng `base_quantity_micros` + ghi dòng (`012`)

**Interfaces:**
- Produces: `sales._product_unit_conversion_rate(p_tenant_id uuid, p_product_id uuid, p_product_unit_id uuid) returns numeric`; `sales._base_quantity_micros(p_quantity_micros bigint, p_conversion_rate numeric) returns bigint`.

- [ ] **Step 1: Thêm test (fail)** — thêm vào cuối `main()`:

```dart
  final rxSql = _readMigration('20260830012_sales_return_exchange_session_rpcs.sql');

  test('conversion helpers mirror checkout rules', () {
    final rate = _lastFunctionBlock(rxSql, 'sales._product_unit_conversion_rate');
    expect(rate, contains('from catalog.products p'));
    expect(rate, contains('pu.conversion_rate_to_base'));
    expect(rate, contains("'PRODUCT_NOT_SELLABLE'"));
    final base = _lastFunctionBlock(rxSql, 'sales._base_quantity_micros');
    expect(base, contains("'INVALID_QUANTITY'"));
    expect(base, contains('v_base <> trunc(v_base)'));
    expect(
      rxSql.indexOf('create or replace function sales._base_quantity_micros('),
      lessThan(rxSql.indexOf('create or replace function sales.start_return_exchange(')),
    );
  });

  for (final fn in ['sales.start_return_exchange', 'sales.update_return_exchange']) {
    test('$fn stores converted base quantity and no dropped columns', () {
      final body = _lastFunctionBlock(rxSql, fn);
      expect(body, contains('v_base_qty := sales._base_quantity_micros('));
      expect(body, contains("'conversionRateToBase',\n        sales._product_unit_conversion_rate("));
      expect(body, contains('v_qty, v_base_qty, v_unit_price_minor,'));
      expect(body, isNot(contains('v_qty, v_qty')));
      final start = body.indexOf('insert into sales.return_exchange_lines (');
      final insert = body.substring(start, body.indexOf('end loop;', start));
      for (final column in removed) {
        expect(insert, isNot(contains(column)), reason: column);
      }
      expect(insert, isNot(contains("'unitPriceMinor'")));
      expect(body, contains('sol.product_id, sol.product_unit_id'));
      expect(body, contains('rl.product_id, rl.product_unit_id'));
      expect(body, contains('Hàng trả phải cùng sản phẩm và đơn vị với dòng gốc.'));
    });
  }
```

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_13_return_exchange_lines_sql_contract_test.dart`
Expected: FAIL 3 test mới.

- [ ] **Step 3: Thêm 2 helper đầu `20260830012`** — chèn ngay sau dòng header `-- Generated by …` (trước `create or replace function sales.precheck_return_exchange(`):

```sql
-- Unit conversion for exchanged-in goods: same sellability rules as checkout.
create or replace function sales._product_unit_conversion_rate(
  p_tenant_id uuid,
  p_product_id uuid,
  p_product_unit_id uuid
) returns numeric
language plpgsql
stable
security definer
set search_path = sales, catalog, public, pg_temp
as $$
declare
  v_rate numeric;
begin
  select pu.conversion_rate_to_base
  into v_rate
  from catalog.products p
  join catalog.product_units pu
    on pu.tenant_id = p.tenant_id
   and pu.product_id = p.id
  where p.tenant_id = p_tenant_id
    and p.id = p_product_id
    and p.business_status = 'active'::catalog.product_business_status
    and p.is_ready_to_sell = true
    and pu.id = p_product_unit_id
    and pu.is_active = true;

  if not found then
    raise exception using message = jsonb_build_object(
      'code', 'PRODUCT_NOT_SELLABLE',
      'message', 'Sản phẩm đã ngừng bán. Vui lòng chọn sản phẩm khác.'
    )::text;
  end if;
  return v_rate;
end;
$$;

-- Base quantity = quantity × conversion rate; whole base units only (checkout rule).
create or replace function sales._base_quantity_micros(
  p_quantity_micros bigint,
  p_conversion_rate numeric
) returns bigint
language plpgsql
immutable
set search_path = sales, public, pg_temp
as $$
declare
  v_base numeric;
begin
  if p_conversion_rate is null or p_conversion_rate <= 0 then
    raise exception using message = jsonb_build_object(
      'code', 'INVALID_QUANTITY',
      'message', 'Missing or invalid unit conversion rate.'
    )::text;
  end if;
  v_base := p_quantity_micros::numeric * p_conversion_rate;
  if v_base <> trunc(v_base)
     or v_base <= 0
     or v_base > 9223372036854775807 then
    raise exception using message = jsonb_build_object(
      'code', 'INVALID_QUANTITY',
      'message', 'Base quantity is fractional or out of range.'
    )::text;
  end if;
  return v_base::bigint;
end;
$$;

revoke all on function sales._product_unit_conversion_rate(uuid, uuid, uuid) from public, anon, authenticated;
revoke all on function sales._base_quantity_micros(bigint, numeric) from public, anon, authenticated;

```

- [ ] **Step 4: Header `20260830012`** — thêm `_product_unit_conversion_rate, _base_quantity_micros` vào cuối `-- Touches:`.

- [ ] **Step 5: Sửa `start_return_exchange`**

1. `declare`: ngay sau `  v_qty bigint;` thêm:

```sql
  v_base_qty bigint;
  v_src_product_id uuid;
  v_src_product_unit_id uuid;
```

2. Trong nhánh `returned`, lấy thêm sản phẩm/đơn vị của dòng nguồn — sửa 2 câu select:

```sql
-- trước (nguồn = dòng đổi)
        select rl.unit_value_minor, rl.product_snapshot, rl.product_unit_snapshot
          into v_unit_price_minor, v_product_snapshot, v_unit_snapshot
-- sau
        select rl.unit_value_minor, rl.product_snapshot, rl.product_unit_snapshot,
               rl.product_id, rl.product_unit_id
          into v_unit_price_minor, v_product_snapshot, v_unit_snapshot,
               v_src_product_id, v_src_product_unit_id

-- trước (nguồn = dòng đơn gốc)
        select sol.unit_price_minor, sol.product_snapshot, sol.product_unit_snapshot
          into v_unit_price_minor, v_product_snapshot, v_unit_snapshot
-- sau
        select sol.unit_price_minor, sol.product_snapshot, sol.product_unit_snapshot,
               sol.product_id, sol.product_unit_id
          into v_unit_price_minor, v_product_snapshot, v_unit_snapshot,
               v_src_product_id, v_src_product_unit_id
```

3. Ngay trước `    insert into sales.return_exchange_lines (` (trong vòng lặp dòng) chèn:

```sql
    if v_role = 'returned'
       and (v_src_product_id is distinct from (v_line ->> 'product_id')::uuid
         or v_src_product_unit_id is distinct from (v_line ->> 'product_unit_id')::uuid) then
      raise exception using message = jsonb_build_object(
        'code', 'RETURN_EXCHANGE_BLOCKED',
        'message', 'Hàng trả phải cùng sản phẩm và đơn vị với dòng gốc.'
      )::text;
    end if;
    if v_role = 'exchange' then
      v_unit_snapshot := coalesce(v_unit_snapshot, '{}'::jsonb) || jsonb_build_object(
        'conversionRateToBase',
        sales._product_unit_conversion_rate(
          start_return_exchange.tenant_id,
          (v_line ->> 'product_id')::uuid,
          (v_line ->> 'product_unit_id')::uuid
        )
      );
    end if;
    v_base_qty := sales._base_quantity_micros(
      v_qty, (v_unit_snapshot ->> 'conversionRateToBase')::numeric
    );

```

4. Thay cả câu insert dòng bằng:

```sql
    insert into sales.return_exchange_lines (
      id, tenant_id, return_exchange_order_id, source_sales_order_id, line_sequence,
      line_role, original_sales_order_line_id, source_exchange_line_id, product_id, product_unit_id,
      quantity_micros, base_quantity_micros, unit_value_minor,
      return_reason_code, return_condition_code, product_snapshot, product_unit_snapshot
    ) values (
      v_line_id, start_return_exchange.tenant_id, v_session_id, v_order.id, v_line_seq,
      v_role, v_orig, v_src_exchange, (v_line ->> 'product_id')::uuid, (v_line ->> 'product_unit_id')::uuid,
      v_qty, v_base_qty, v_unit_price_minor,
      case when v_role = 'returned' then upper(nullif(btrim(v_line ->> 'reason_code'), '')) else null end,
      case when v_role = 'returned' then upper(nullif(btrim(v_line ->> 'condition_code'), '')) else null end,
      coalesce(v_product_snapshot, '{}'::jsonb),
      coalesce(v_unit_snapshot, '{}'::jsonb)
    );
```

- [ ] **Step 6: Sửa `update_return_exchange`** — giống Step 5, thay `start_return_exchange.tenant_id` bằng `update_return_exchange.tenant_id` và `v_session_id` bằng `v_session.id`:

1. `declare`: sau `  v_qty bigint;` thêm 3 biến như Step 5.1.
2. Sửa 2 câu select trong nhánh `returned` như Step 5.2.
3. Chèn khối kiểm tra khớp nguồn + tính hệ số như Step 5.3, ngay trước `    insert into sales.return_exchange_lines (` (dùng `update_return_exchange.tenant_id`).
4. Thay câu insert dòng bằng:

```sql
    insert into sales.return_exchange_lines (
      id, tenant_id, return_exchange_order_id, source_sales_order_id, line_sequence,
      line_role, original_sales_order_line_id, source_exchange_line_id, product_id, product_unit_id,
      quantity_micros, base_quantity_micros, unit_value_minor,
      return_reason_code, return_condition_code, product_snapshot, product_unit_snapshot
    ) values (
      v_line_id, update_return_exchange.tenant_id, v_session.id, v_order.id, v_line_seq,
      v_role, v_orig, v_src_exchange, (v_line ->> 'product_id')::uuid, (v_line ->> 'product_unit_id')::uuid,
      v_qty, v_base_qty, v_unit_price_minor,
      case when v_role = 'returned' then upper(nullif(btrim(v_line ->> 'reason_code'), '')) else null end,
      case when v_role = 'returned' then upper(nullif(btrim(v_line ->> 'condition_code'), '')) else null end,
      coalesce(v_product_snapshot, '{}'::jsonb),
      coalesce(v_unit_snapshot, '{}'::jsonb)
    );
```

- [ ] **Step 7: Chạy test, xác nhận pass**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_13_return_exchange_lines_sql_contract_test.dart test/domain/schema/sales_refactor_12_return_exchange_orders_sql_contract_test.dart test/domain/return_exchange_order/sales_return_exchange_group_i_session_sql_contract_test.dart`
Expected: PASS.

- [ ] **Step 8: Tóm tắt + đề xuất commit, dừng chờ review**

Đề xuất: `fix(sales): compute return/exchange line base quantity from unit conversion`

---

### Task 3: Bỏ nhánh `pricing_snapshot` trong định giá (`013`)

- [ ] **Step 1: Thêm test (fail)** — thêm vào cuối `main()`:

```dart
  test('valuation no longer reads pricing_snapshot', () {
    final evaluate = _lastFunctionBlock(
      _readMigration('20260830013_sales_return_exchange_settlement_rpcs.sql'),
      'sales.evaluate_return_exchange_valuation',
    );
    expect(evaluate, isNot(contains('pricing_snapshot')));
    expect(evaluate, contains('v_unit_price_minor := v_line.unit_value_minor;'));
  });
```

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_13_return_exchange_lines_sql_contract_test.dart`
Expected: FAIL test mới.

- [ ] **Step 3: Sửa `evaluate_return_exchange_valuation` (`20260830013`)**

1. Trong select của vòng lặp:

```sql
-- trước
      rl.unit_value_minor,
      rl.pricing_snapshot
    from sales.return_exchange_lines rl
-- sau
      rl.unit_value_minor
    from sales.return_exchange_lines rl
```

2. Xoá khối (kèm dòng trống theo sau nếu có):

```sql
      if v_unit_price_minor is null
        and v_line.pricing_snapshot is not null
        and v_line.pricing_snapshot ? 'unit_price_minor' then
        v_unit_price_minor := (v_line.pricing_snapshot ->> 'unit_price_minor')::bigint;
      end if;
```

- [ ] **Step 4: Chạy test, xác nhận pass**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_13_return_exchange_lines_sql_contract_test.dart`
Expected: PASS.

- [ ] **Step 5: Grep + registry + policy + toàn bộ test**
- `grep -nE "line_value_minor|rl\.pricing_snapshot|returned_source_xor|v_qty, v_qty" supabase/migrations/*.sql` → không còn kết quả.
- `dart run tools/vet45_supabase_migrate/bin/seed_registry.dart --write && dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart --strict` → OK; `REGISTRY.yaml` thêm 2 helper.
- `cd modules/sales/infrastructure && dart test` → chỉ còn baseline fail.

- [ ] **Step 6: Tiến độ spec** — dòng bảng 13 README: `✅ Đã chốt · base_quantity tính đúng, bỏ 4 cột, dọn CHECK/alter · 📝 Plan … · 🧪 Đã sửa migration gốc, chờ reset`.

- [ ] **Step 7: Tóm tắt + đề xuất commit, dừng — user reset + smoke test**

Đề xuất commit: `refactor(sales): drop return/exchange line pricing snapshot fallback`

Sau `supabase db reset` (cần sản phẩm có đơn vị quy đổi, ví dụ Hộp = 10 Viên):
1. Bán 2 Hộp → đổi trả: trả 1 Hộp, đổi lấy 3 Viên → lưu + xác nhận thành công.
2. SQL Editor: `select line_role, product_unit_id, quantity_micros, base_quantity_micros, product_unit_snapshot from sales.return_exchange_lines order by created_at desc limit 5;` → dòng trả `base = 10 × quantity`; dòng đổi `base = quantity × hệ số` và `product_unit_snapshot` có `conversionRateToBase`.
3. Trả tiếp hàng vừa đổi vào (3 Viên) ở phiếu mới → `base_quantity_micros` đúng theo hệ số của dòng đổi nguồn.
3b. SQL Editor: gọi `sales.start_return_exchange(...)` với dòng trả trỏ dòng gốc Hộp nhưng `product_unit_id` của Viên → lỗi "Hàng trả phải cùng sản phẩm và đơn vị với dòng gốc."
4. Định giá/chênh lệch vẫn đúng như trước.
