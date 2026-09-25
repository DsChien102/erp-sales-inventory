# Sales refactor — Bảng 6 `sales.sales_order_lines` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bỏ `pricing_snapshot`, `tax_snapshot` của `sales.sales_order_lines`; biến bảng thành nguồn dòng hàng duy nhất (bỏ `lines` khỏi `sales_orders.sales_context_snapshot`, chi tiết đơn + hoá đơn dựng `lines` từ bảng qua helper mới) — **sửa trực tiếp migration gốc**, giữ key JSON.

**Architecture:** Bảng ở `20260830005`. Finalize (`20260830008`) thôi dựng `v_normalized_lines`. Helper `sales._sales_order_lines_payload` (language sql) đặt đầu `20260830010`, dùng ở `get_sales_order_detail` và `generate_sales_receipt`. Đổi trả (`20260830012`) bỏ nhánh dự phòng đọc snapshot.

**Tech Stack:** PostgreSQL/Supabase plpgsql + sql; Dart `package:test`.

**Spec:** [06-sales-order-lines.md](../specs/sales-schema-refactor/06-sales-order-lines.md) · Quy ước: [README §Quy ước implement](../specs/sales-schema-refactor/README.md#quy-ước-implement-sửa-trực-tiếp-migration-gốc)

## Global Constraints

- Tuân thủ **Quy ước implement**. Thứ tự: sau plan 1–5 (cùng sửa `finalize_sales_order`, `generate_sales_receipt`) — tìm theo nội dung, không theo số dòng.
- Key JSON `lines[]` của chi tiết đơn và hoá đơn giữ nguyên: `lineId`, `product`, `unit`, `quantityMicros`, `unitPrice`, `discountTotal`, `lineTotal` (dư `note`, `unit.conversionRateToBase` là chấp nhận được).
- Không sửa 2 lỗi dòng đổi trả (để bảng 13). Không sửa draft theme8.
- Không `dart format` cả package; chỉ file test mới.
- **Không `git commit`** — cuối mỗi task tóm tắt + đề xuất commit rồi dừng.
- Trước khi sửa hàm: `node .gitnexus/run.cjs impact "<tên hàm>" --direction upstream --repo .` cho `finalize_sales_order`, `get_sales_order_detail`, `generate_sales_receipt`, `get_returnable_order_lines`, `start_return_exchange` (hàm SQL → `UNKNOWN`; đối chiếu khảo sát).

## Khảo sát

| Vị trí | Nội dung |
|---|---|
| `20260830005` `create table if not exists sales.sales_order_lines` | có `pricing_snapshot jsonb not null`, `tax_snapshot jsonb` |
| `20260830005` khối SCHEMA EVOLUTION | cặp `drop/add constraint sales_order_lines_base_qty_positive` và `sales_order_lines_commercial_balance` |
| `20260830008` `finalize_sales_order` | `declare v_normalized_lines jsonb := '[]'::jsonb;`; khối `v_normalized_lines := v_normalized_lines || jsonb_build_array(…);` trong vòng lặp dòng; key `'lines', v_normalized_lines` trong `v_normalized_commercial_snapshot`; insert `sales_order_lines` có `pricing_snapshot` |
| `20260830010` `get_sales_order_detail` | `'lines', coalesce(v_order.sales_context_snapshot -> 'lines', '[]'::jsonb),` |
| `20260830010` `generate_sales_receipt` | `declare v_lines jsonb;`; `select coalesce(jsonb_agg(jsonb_build_object('lineId', line.id, …)), '[]'::jsonb) into v_lines from sales.sales_order_lines line …`; `'lines', coalesce(nullif(v_order.sales_context_snapshot -> 'lines', 'null'::jsonb), v_lines),` |
| `20260830012` `get_returnable_order_lines` | 2 subquery dự phòng `from jsonb_array_elements(coalesce(v_order.sales_context_snapshot -> 'lines', …))` trong `displayName`, `unitName` |
| `20260830012` `start_return_exchange` | khối `if nullif(btrim(coalesce(v_product_snapshot ->> 'displayName', '')), '') is null then … sales_context_snapshot -> 'lines' … end if;` |
| Test | `sales_return_exchange_group_i_session_sql_contract_test.dart:66` `expect(returnableSql, contains('sales_context_snapshot'));` |
| Nơi khác | Không ai đọc `pricing_snapshot`/`tax_snapshot` của dòng đơn (cả `feature/theme8`); `013` đọc `pricing_snapshot` của **dòng đổi trả** (bảng khác) |

## File Structure

| File | Thay đổi |
|---|---|
| Modify `supabase/migrations/20260830005_sales_rebuild_schema.sql` | `create table` + xoá alter cũ |
| Modify `supabase/migrations/20260830008_sales_checkout_rpcs.sql` | finalize |
| Modify `supabase/migrations/20260830010_sales_inquiry_receipt_rpcs.sql` | helper mới, detail, receipt, header |
| Modify `supabase/migrations/20260830012_sales_return_exchange_session_rpcs.sql` | bỏ dự phòng |
| Modify `modules/sales/infrastructure/test/domain/return_exchange_order/sales_return_exchange_group_i_session_sql_contract_test.dart:66` | assertion |
| Create `modules/sales/infrastructure/test/domain/schema/sales_refactor_06_order_lines_sql_contract_test.dart` | SQL contract test |
| Modify `supabase/migrations/REGISTRY.yaml` | qua `seed_registry --write` |
| Modify `docs/superpowers/specs/sales-schema-refactor/README.md` | Tiến độ |

---

### Task 1: Bảng + finalize (`005`, `008`)

- [ ] **Step 1: Viết test (fail)**

```dart
import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Sales refactor bảng 6 `sales.sales_order_lines`
/// (docs/superpowers/specs/sales-schema-refactor/06-sales-order-lines.md).
void main() {
  final schemaSql = _readMigration('20260830005_sales_rebuild_schema.sql');
  final checkoutSql = _readMigration('20260830008_sales_checkout_rpcs.sql');

  test('order lines drop pricing/tax snapshots and own their checks', () {
    final start = schemaSql.indexOf('create table if not exists sales.sales_order_lines (');
    final table = schemaSql.substring(start, schemaSql.indexOf('\n);', start));
    expect(table, isNot(contains('pricing_snapshot')));
    expect(table, isNot(contains('tax_snapshot')));
    expect(table, contains('constraint sales_order_lines_base_qty_positive'));
    expect(table, contains('constraint sales_order_lines_commercial_balance'));
    expect(schemaSql, isNot(contains('alter table sales.sales_order_lines')));
  });

  test('finalize no longer copies lines into sales_context_snapshot', () {
    final finalize = _lastFunctionBlock(checkoutSql, 'sales.finalize_sales_order');
    expect(finalize, isNot(contains('v_normalized_lines')));
    final snapStart = finalize.indexOf('v_normalized_commercial_snapshot := jsonb_build_object(');
    final snapshot = finalize.substring(snapStart, finalize.indexOf('\n    );', snapStart));
    expect(snapshot, isNot(contains("'lines'")));
    final insertStart = finalize.indexOf('insert into sales.sales_order_lines(');
    final insert = finalize.substring(insertStart, finalize.indexOf('end loop;', insertStart));
    expect(insert, isNot(contains('pricing_snapshot')));
    expect(insert, contains('product_snapshot, product_unit_snapshot, line_note'));
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

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_06_order_lines_sql_contract_test.dart`
Expected: FAIL 2 test.

- [ ] **Step 3: Sửa `create table` trong `20260830005`** — thay cả khối `create table if not exists sales.sales_order_lines (…);` bằng:

```sql
create table if not exists sales.sales_order_lines (
  id uuid primary key,
  tenant_id uuid not null,
  sales_order_id uuid not null,
  line_sequence integer not null,
  product_id uuid not null,
  product_unit_id uuid not null,
  quantity_micros bigint not null,
  base_quantity_micros bigint not null,
  unit_price_minor bigint not null,
  gross_amount_minor bigint not null,
  discount_amount_minor bigint not null,
  tax_amount_minor bigint not null,
  line_total_minor bigint not null,
  product_snapshot jsonb not null,
  product_unit_snapshot jsonb not null,
  line_note text,
  created_at timestamptz not null default now(),
  constraint sales_order_lines_seq_unique unique (sales_order_id, line_sequence), -- FC-06
  constraint sales_order_lines_qty_positive check (quantity_micros > 0),          -- FC-13
  constraint sales_order_lines_base_qty_positive check (base_quantity_micros > 0),
  constraint sales_order_lines_commercial_balance
    check (line_total_minor
      = gross_amount_minor - discount_amount_minor + tax_amount_minor),
  constraint sales_order_lines_parent_fk
    foreign key (tenant_id, sales_order_id)
    references sales.sales_orders (tenant_id, id) on delete cascade,             -- FC-01
  constraint sales_order_lines_tenant_id_unique unique (tenant_id, id),          -- returned-line reference target
  constraint sales_order_lines_tenant_id_id_order_unique
    unique (tenant_id, id, sales_order_id)                                      -- FC-12 composite target
);
```

- [ ] **Step 4: Xoá alter cũ trong khối SCHEMA EVOLUTION (`20260830005`)** — xoá 2 đoạn (kèm dòng trống theo sau):

```sql
alter table sales.sales_order_lines
  drop constraint if exists sales_order_lines_base_qty_positive;
alter table sales.sales_order_lines
  add constraint sales_order_lines_base_qty_positive
  check (base_quantity_micros > 0);
```

```sql
alter table sales.sales_order_lines
  drop constraint if exists sales_order_lines_commercial_balance;
alter table sales.sales_order_lines
  add constraint sales_order_lines_commercial_balance
  check (line_total_minor
    = gross_amount_minor - discount_amount_minor + tax_amount_minor);
```

- [ ] **Step 5: Sửa `finalize_sales_order` (`20260830008`)**

1. `declare`: xoá dòng `  v_normalized_lines jsonb := '[]'::jsonb;`.
2. Trong vòng lặp dòng, xoá nguyên khối (ngay sau `      v_order_line_id := gen_random_uuid();`, ngay trước `      v_persisted_line_inputs := v_persisted_line_inputs || jsonb_build_array(`):

```sql
      v_normalized_lines := v_normalized_lines || jsonb_build_array(
        jsonb_build_object(
          'lineId', v_order_line_id::text,
          'product', jsonb_build_object(
            'productId', trim(v_commercial_line -> 'product' ->> 'productId'),
            'sku', nullif(trim(coalesce(v_commercial_line -> 'product' ->> 'sku', '')), ''),
            'displayName', trim(v_commercial_line -> 'product' ->> 'displayName')
          ),
          'unit', jsonb_build_object(
            'productUnitId', trim(v_commercial_line -> 'unit' ->> 'productUnitId'),
            'unitCode', nullif(trim(coalesce(v_commercial_line -> 'unit' ->> 'unitCode', '')), ''),
            'unitName', trim(v_commercial_line -> 'unit' ->> 'unitName')
          ),
          'quantityMicros', (v_line ->> 'quantity_micros')::bigint,
          'unitPrice', jsonb_build_object(
            'amountMinor', (v_line -> 'unit_price' ->> 'amount_minor')::bigint,
            'currencyCode', v_currency_code
          ),
          'discountTotal', jsonb_build_object('amountMinor', v_discount_minor, 'currencyCode', v_currency_code),
          'lineTotal', jsonb_build_object(
            'amountMinor', v_line_total_minor,
            'currencyCode', v_currency_code
          )
        )
      );
```

3. Cuối `v_normalized_commercial_snapshot`:

```sql
-- trước
          'taxCode', nullif(trim(coalesce(p_commercial_snapshot -> 'customer' ->> 'taxCode', '')), '')
        )
      end,
      'lines', v_normalized_lines
    );
-- sau
          'taxCode', nullif(trim(coalesce(p_commercial_snapshot -> 'customer' ->> 'taxCode', '')), '')
        )
      end
    );
```

4. Insert `sales_order_lines`:

```sql
-- trước
        discount_amount_minor, tax_amount_minor, line_total_minor,
        product_snapshot, product_unit_snapshot, pricing_snapshot, line_note
      ) values (
        …
        coalesce(v_line -> 'product_snapshot', '{}'::jsonb),
        coalesce(v_line -> 'product_unit_snapshot', '{}'::jsonb),
        jsonb_build_object(
          'unitPriceMinor', (v_line ->> 'unit_price_minor')::bigint,
          'lineTotalMinor', (v_line ->> 'line_total_minor')::bigint
        ),
        nullif(trim(coalesce(v_line ->> 'note', '')), '')
      );
-- sau
        discount_amount_minor, tax_amount_minor, line_total_minor,
        product_snapshot, product_unit_snapshot, line_note
      ) values (
        …
        coalesce(v_line -> 'product_snapshot', '{}'::jsonb),
        coalesce(v_line -> 'product_unit_snapshot', '{}'::jsonb),
        nullif(trim(coalesce(v_line ->> 'note', '')), '')
      );
```

(`…` = các dòng giá trị ở giữa, giữ nguyên.)

- [ ] **Step 6: Chạy test, xác nhận pass**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_06_order_lines_sql_contract_test.dart test/domain/sales_order/sales_checkout_group_d_sql_contract_test.dart`
Expected: PASS.

- [ ] **Step 7: Tóm tắt + đề xuất commit, dừng chờ review**

Đề xuất: `refactor(sales): drop order line pricing/tax snapshots and snapshot line copy`

---

### Task 2: Helper dựng `lines` + chi tiết đơn + hoá đơn (`010`)

**Interfaces:**
- Produces: `sales._sales_order_lines_payload(p_tenant_id uuid, p_sales_order_id uuid, p_currency_code text) returns jsonb` — mảng `[{lineId, product, unit, quantityMicros, unitPrice{amountMinor,currencyCode}, discountTotal{…}, lineTotal{…}, note}]` sắp theo `line_sequence, id`; `'[]'` nếu không có dòng.

- [ ] **Step 1: Thêm test (fail)** — thêm vào cuối `main()`:

```dart
  final inquirySql = _readMigration('20260830010_sales_inquiry_receipt_rpcs.sql');

  test('order lines payload helper builds lines from the table', () {
    final helper = _lastFunctionBlock(inquirySql, 'sales._sales_order_lines_payload');
    expect(helper, contains('language sql'));
    expect(helper, contains('from sales.sales_order_lines line'));
    expect(helper, contains('order by line.line_sequence, line.id'));
    expect(
      inquirySql,
      contains(
        'revoke all on function sales._sales_order_lines_payload(uuid, uuid, text) from public, anon, authenticated;',
      ),
    );
    expect(inquirySql.indexOf('create or replace function sales._sales_order_lines_payload('),
        lessThan(inquirySql.indexOf('create or replace function sales.get_sales_order(')));
  });

  test('detail and receipt read lines through the helper', () {
    final detail = _lastFunctionBlock(inquirySql, 'sales.get_sales_order_detail');
    expect(
      detail,
      contains("'lines', sales._sales_order_lines_payload(v_order.tenant_id, v_order.id, v_order.currency_code),"),
    );
    final receipt = _lastFunctionBlock(inquirySql, 'sales.generate_sales_receipt');
    expect(
      receipt,
      contains("'lines', sales._sales_order_lines_payload(p_tenant_id, p_sales_order_id, v_order.currency_code),"),
    );
    expect(receipt, isNot(contains('v_lines')));
    expect(inquirySql, isNot(contains("sales_context_snapshot -> 'lines'")));
  });
```

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_06_order_lines_sql_contract_test.dart`
Expected: FAIL 2 test mới.

- [ ] **Step 3: Thêm helper đầu `20260830010`** — chèn ngay sau dòng header `-- Generated by …` (trước `create or replace function sales.get_sales_order(`):

```sql
create or replace function sales._sales_order_lines_payload(
  p_tenant_id uuid,
  p_sales_order_id uuid,
  p_currency_code text
) returns jsonb
language sql
stable
security definer
set search_path = sales, iam, public, pg_temp
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'lineId', line.id,
    'product', line.product_snapshot,
    'unit', line.product_unit_snapshot,
    'quantityMicros', line.quantity_micros,
    'unitPrice', jsonb_build_object(
      'amountMinor', line.unit_price_minor,
      'currencyCode', p_currency_code
    ),
    'discountTotal', jsonb_build_object(
      'amountMinor', line.discount_amount_minor,
      'currencyCode', p_currency_code
    ),
    'lineTotal', jsonb_build_object(
      'amountMinor', line.line_total_minor,
      'currencyCode', p_currency_code
    ),
    'note', line.line_note
  ) order by line.line_sequence, line.id), '[]'::jsonb)
  from sales.sales_order_lines line
  where line.tenant_id = p_tenant_id
    and line.sales_order_id = p_sales_order_id;
$$;

revoke all on function sales._sales_order_lines_payload(uuid, uuid, text) from public, anon, authenticated;

```

- [ ] **Step 4: Header `20260830010`** — thêm `_sales_order_lines_payload` vào cuối danh sách `-- Touches:` (sau `_sales_receipt_envelope`).

- [ ] **Step 5: Sửa `get_sales_order_detail`**

```sql
-- trước
    'lines', coalesce(v_order.sales_context_snapshot -> 'lines', '[]'::jsonb),
-- sau
    'lines', sales._sales_order_lines_payload(v_order.tenant_id, v_order.id, v_order.currency_code),
```

- [ ] **Step 6: Sửa `generate_sales_receipt`**

1. `declare`: xoá dòng `  v_lines jsonb;`.
2. Xoá nguyên câu (nằm ngay sau câu select `v_payments` … `and transaction.sales_order_settlement_id = v_settlement.id;`):

```sql
  select coalesce(jsonb_agg(jsonb_build_object(
    'lineId', line.id,
    'product', line.product_snapshot,
    'unit', line.product_unit_snapshot,
    'quantityMicros', line.quantity_micros,
    'unitPrice', jsonb_build_object(
      'amountMinor', line.unit_price_minor,
      'currencyCode', v_order.currency_code
    ),
    'discountTotal', jsonb_build_object(
      'amountMinor', line.discount_amount_minor,
      'currencyCode', v_order.currency_code
    ),
    'lineTotal', jsonb_build_object(
      'amountMinor', line.line_total_minor,
      'currencyCode', v_order.currency_code
    ),
    'note', line.line_note
  ) order by line.line_sequence, line.id), '[]'::jsonb)
  into v_lines
  from sales.sales_order_lines line
  where line.tenant_id = p_tenant_id
    and line.sales_order_id = p_sales_order_id;

```

3. Key `lines` trong `v_snapshot`:

```sql
-- trước
    'lines', coalesce(
      nullif(v_order.sales_context_snapshot -> 'lines', 'null'::jsonb),
      v_lines
    ),
-- sau
    'lines', sales._sales_order_lines_payload(p_tenant_id, p_sales_order_id, v_order.currency_code),
```

- [ ] **Step 7: Chạy test, xác nhận pass**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_06_order_lines_sql_contract_test.dart test/domain/schema/sales_refactor_05_orders_sql_contract_test.dart`
Expected: PASS.

- [ ] **Step 8: Tóm tắt + đề xuất commit, dừng chờ review**

Đề xuất: `refactor(sales): build order detail and receipt lines from sales_order_lines`

---

### Task 3: Bỏ dự phòng đọc snapshot ở đổi trả (`012`)

- [ ] **Step 1: Thêm test (fail)** — thêm vào cuối `main()`:

```dart
  test('return/exchange no longer falls back to snapshot lines', () {
    final rxSql = _readMigration('20260830012_sales_return_exchange_session_rpcs.sql');
    expect(rxSql, isNot(contains('sales_context_snapshot')));
    final returnable = _lastFunctionBlock(rxSql, 'sales.get_returnable_order_lines');
    expect(
      returnable,
      contains(
        "'displayName', coalesce(\n"
        "          nullif(btrim(l.product_snapshot ->> 'displayName'), ''),\n"
        '          l.product_id::text\n'
        '        )',
      ),
    );
  });
```

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_06_order_lines_sql_contract_test.dart`
Expected: FAIL test mới.

- [ ] **Step 3: Sửa `get_returnable_order_lines`** — 2 chỗ:

```sql
-- trước
        'displayName', coalesce(
          nullif(btrim(l.product_snapshot ->> 'displayName'), ''),
          (
            select nullif(btrim(elem -> 'product' ->> 'displayName'), '')
            from jsonb_array_elements(coalesce(v_order.sales_context_snapshot -> 'lines', '[]'::jsonb)) elem
            where (elem ->> 'lineId') = l.id::text
            limit 1
          ),
          l.product_id::text
        )
-- sau
        'displayName', coalesce(
          nullif(btrim(l.product_snapshot ->> 'displayName'), ''),
          l.product_id::text
        )
```

```sql
-- trước
        'unitName', coalesce(
          nullif(btrim(l.product_unit_snapshot ->> 'unitName'), ''),
          (
            select nullif(btrim(elem -> 'unit' ->> 'unitName'), '')
            from jsonb_array_elements(coalesce(v_order.sales_context_snapshot -> 'lines', '[]'::jsonb)) elem
            where (elem ->> 'lineId') = l.id::text
            limit 1
          ),
          l.product_unit_id::text
        )
-- sau
        'unitName', coalesce(
          nullif(btrim(l.product_unit_snapshot ->> 'unitName'), ''),
          l.product_unit_id::text
        )
```

- [ ] **Step 4: Sửa `start_return_exchange`** — xoá nguyên khối (ngay sau khối `if v_unit_price_minor is null then … 'Returned line commercial unit price snapshot is missing.' … end if;`):

```sql
        if nullif(btrim(coalesce(v_product_snapshot ->> 'displayName', '')), '') is null then
          select coalesce(elem -> 'product', '{}'::jsonb), coalesce(elem -> 'unit', '{}'::jsonb)
            into v_product_snapshot, v_unit_snapshot
          from jsonb_array_elements(coalesce(v_order.sales_context_snapshot -> 'lines', '[]'::jsonb)) elem
          where (elem ->> 'lineId') = v_orig::text
          limit 1;
        end if;
```

- [ ] **Step 5: Sửa test cũ** `sales_return_exchange_group_i_session_sql_contract_test.dart:66`:

```dart
    expect(returnableSql, isNot(contains('sales_context_snapshot')));
```

- [ ] **Step 6: Chạy test, xác nhận pass**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_06_order_lines_sql_contract_test.dart test/domain/return_exchange_order/sales_return_exchange_group_i_session_sql_contract_test.dart`
Expected: PASS.

- [ ] **Step 7: Tóm tắt + đề xuất commit, dừng chờ review**

Đề xuất: `refactor(sales): drop snapshot line fallback in return/exchange`

---

### Task 4: Kiểm chứng + tiến độ

- [ ] **Step 1: Grep toàn bộ migration**

Run: `grep -nE "sales_context_snapshot *-> *'lines'|v_normalized_lines|\.tax_snapshot|tax_snapshot jsonb" supabase/migrations/2026083*.sql supabase/migrations/20260904001*.sql`
Expected: không còn kết quả.

Run: `grep -n "pricing_snapshot" supabase/migrations/20260830005_sales_rebuild_schema.sql supabase/migrations/20260830008_sales_checkout_rpcs.sql supabase/migrations/20260830010_sales_inquiry_receipt_rpcs.sql`
Expected: chỉ còn `pricing_snapshot` của `return_exchange_lines` trong `005`.

- [ ] **Step 2: Registry + policy**

Run: `dart run tools/vet45_supabase_migrate/bin/seed_registry.dart --write && dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart --strict`
Expected: OK; `REGISTRY.yaml` thêm `_sales_order_lines_payload: 20260830010_sales_inquiry_receipt_rpcs.sql`.

- [ ] **Step 3: Chạy toàn bộ test Sales infrastructure**

Run: `cd modules/sales/infrastructure && dart test`
Expected: chỉ còn baseline fail.

- [ ] **Step 4: Tiến độ spec** — dòng bảng 6 README: `✅ Đã chốt · bỏ 2 snapshot, bảng là nguồn dòng hàng duy nhất · 📝 Plan … · 🧪 Đã sửa migration gốc, chờ reset`.

- [ ] **Step 5: Dừng — user reset + smoke test**

Sau `supabase db reset`:
1. Thanh toán đơn 2 dòng (1 dòng có giảm giá, 1 dòng có ghi chú).
2. Chi tiết đơn → dòng hàng đúng tên, đơn vị, số lượng, đơn giá, giảm giá, thành tiền, thứ tự.
3. Tạo hoá đơn → dòng hàng giống chi tiết đơn.
4. Đổi trả: mở danh sách dòng có thể trả → tên sản phẩm, đơn vị đúng; tạo phiếu đổi trả thành công.
5. SQL Editor: `select sales_context_snapshot ? 'lines' from sales.sales_orders order by created_at desc limit 1;` → `false`.
