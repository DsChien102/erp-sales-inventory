# Sales refactor — Bảng 14 `sales.return_exchange_valuations` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bỏ 5 cột chỉ-ghi của `sales.return_exchange_valuations` (`required_settlement_type`, `version`, `calculated_by_user_id`, `confirmed_at`, `updated_at`) và giá trị `superseded` — **sửa trực tiếp migration gốc**, không đổi contract RPC.

**Architecture:** Bảng ở `20260830005`. Ghi ở 3 định nghĩa cuối: `evaluate_return_exchange_valuation`, `settle_return_exchange_difference` (`20260830013`), `confirm_return_exchange` (`20260904001`).

**Tech Stack:** PostgreSQL/Supabase plpgsql; Dart `package:test`.

**Spec:** [14-return-exchange-valuations.md](../specs/sales-schema-refactor/14-return-exchange-valuations.md) · Quy ước: [README §Quy ước implement](../specs/sales-schema-refactor/README.md#quy-ước-implement-sửa-trực-tiếp-migration-gốc)

## Global Constraints

- Tuân thủ **Quy ước implement**. Thứ tự: sau plan 13 (cùng sửa `013`) — tìm theo nội dung.
- Không sửa bản cũ `confirm_return_exchange` trong `20260830014`.
- Không `dart format` cả package; chỉ file test mới.
- **Không `git commit`** — cuối task tóm tắt + đề xuất commit rồi dừng.
- Trước khi sửa hàm: `node .gitnexus/run.cjs impact "<tên hàm>" --direction upstream --repo .` cho `evaluate_return_exchange_valuation`, `settle_return_exchange_difference`, `confirm_return_exchange` (hàm SQL → `UNKNOWN`; đối chiếu khảo sát).

## Khảo sát

| Vị trí | Nội dung |
|---|---|
| `20260830005` `create table if not exists sales.return_exchange_valuations` | có `required_settlement_type`, `version`, `calculated_by_user_id`, `confirmed_at`, `updated_at`; CHECK `settlement_type_check`; `status_check` có `superseded` |
| `20260830013` `evaluate_return_exchange_valuation` | `declare v_required_settlement_type text;`; khối `v_required_settlement_type := case … end;`; upsert có 5 cột bỏ + `on conflict … set …` |
| `20260830013` `settle_return_exchange_difference` | update `… confirmed_at = coalesce(confirmed_at, now()), version = version + 1, updated_at = now()` |
| `20260904001` `confirm_return_exchange` | update `status = 'confirmed', confirmed_at = coalesce(confirmed_at, now()), updated_at = now()` |
| Test | 2 test nhắc `'superseded'` là của hoá đơn (bảng 15) — không ảnh hưởng |

## File Structure

| File | Thay đổi |
|---|---|
| Modify `supabase/migrations/20260830005_sales_rebuild_schema.sql` | `create table` |
| Modify `supabase/migrations/20260830013_sales_return_exchange_settlement_rpcs.sql` | `evaluate`, `settle` |
| Modify `supabase/migrations/20260904001_sales_normalize_outbox_and_commands.sql` | `confirm_return_exchange` |
| Create `modules/sales/infrastructure/test/domain/schema/sales_refactor_14_return_exchange_valuations_sql_contract_test.dart` | SQL contract test |
| Modify `docs/superpowers/specs/sales-schema-refactor/README.md` | Tiến độ |

---

### Task 1: Bỏ 5 cột + `superseded`

- [ ] **Step 1: Viết test (fail)**

```dart
import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Sales refactor bảng 14 `sales.return_exchange_valuations`
/// (docs/superpowers/specs/sales-schema-refactor/14-return-exchange-valuations.md).
void main() {
  final schemaSql = _readMigration('20260830005_sales_rebuild_schema.sql');
  final settlementSql = _readMigration('20260830013_sales_return_exchange_settlement_rpcs.sql');
  const removed = [
    'required_settlement_type',
    'version',
    'calculated_by_user_id',
    'confirmed_at',
    'updated_at',
  ];

  test('valuations table drops write-only columns and superseded', () {
    final start = schemaSql.indexOf(
      'create table if not exists sales.return_exchange_valuations (',
    );
    final table = schemaSql.substring(start, schemaSql.indexOf('\n);', start));
    for (final column in removed) {
      expect(table, isNot(contains(column)), reason: column);
    }
    expect(table, isNot(contains('superseded')));
    expect(table, contains("check (status in ('calculated', 'confirmed'))"));
    expect(table, contains('calculated_at timestamptz not null default now(),'));
  });

  test('evaluate upserts only kept columns', () {
    final evaluate = _lastFunctionBlock(
      settlementSql,
      'sales.evaluate_return_exchange_valuation',
    );
    expect(evaluate, isNot(contains('v_required_settlement_type')));
    final start = evaluate.indexOf('insert into sales.return_exchange_valuations (');
    final upsert = evaluate.substring(start, evaluate.indexOf('returning id into v_valuation_id;', start));
    for (final column in removed) {
      expect(upsert, isNot(contains(column)), reason: column);
    }
  });

  test('settle and confirm updates touch only status/details', () {
    final settle = _lastFunctionBlock(
      settlementSql,
      'sales.settle_return_exchange_difference',
    );
    final settleStart = settle.indexOf('update sales.return_exchange_valuations');
    final settleUpdate = settle.substring(settleStart, settle.indexOf(';', settleStart));
    final confirm = _lastFunctionBlock(
      _readMigration('20260904001_sales_normalize_outbox_and_commands.sql'),
      'sales.confirm_return_exchange',
    );
    final confirmStart = confirm.indexOf('update sales.return_exchange_valuations');
    final confirmUpdate = confirm.substring(confirmStart, confirm.indexOf(';', confirmStart));
    for (final update in [settleUpdate, confirmUpdate]) {
      for (final column in removed) {
        expect(update, isNot(contains(column)), reason: column);
      }
      expect(update, contains('status'));
    }
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

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_14_return_exchange_valuations_sql_contract_test.dart`
Expected: FAIL 3 test.

- [ ] **Step 3: Sửa `create table` trong `20260830005`** — thay cả khối bằng:

```sql
create table if not exists sales.return_exchange_valuations (
  id uuid primary key,
  tenant_id uuid not null,
  return_exchange_order_id uuid not null,
  currency_code char(3) not null,
  return_value_minor bigint not null,
  exchange_value_minor bigint not null,
  net_difference_minor bigint not null,                                        -- signed
  status text not null,
  valuation_details jsonb not null,                                           -- ADR-6: allocation plan embedded here
  calculated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint return_exchange_valuations_order_unique unique (return_exchange_order_id), -- FC-08
  constraint return_exchange_valuations_values_nonneg
    check (return_value_minor >= 0 and exchange_value_minor >= 0),              -- FC-13
  -- FC-14 (ADR-2): canonical sign — exchange minus return.
  constraint return_exchange_valuations_net_formula
    check (net_difference_minor = exchange_value_minor - return_value_minor),
  constraint return_exchange_valuations_status_check
    check (status in ('calculated', 'confirmed')),
  constraint return_exchange_valuations_parent_fk
    foreign key (tenant_id, return_exchange_order_id)
    references sales.return_exchange_orders (tenant_id, id) on delete cascade    -- FC-01
);
```

- [ ] **Step 4: Sửa `evaluate_return_exchange_valuation` (`20260830013`)**

1. `declare`: xoá dòng `  v_required_settlement_type text;`.
2. Xoá nguyên khối (kèm dòng trống theo sau):

```sql
  v_required_settlement_type := case
    when v_net_difference_minor = 0 then 'none'
    when v_collect_amount_minor > 0
      and v_receivable_create_amount_minor = 0
      and v_refund_amount_minor = 0
      and v_receivable_reverse_amount_minor = 0 then 'collect'
    when v_refund_amount_minor > 0
      and v_receivable_reverse_amount_minor = 0
      and v_collect_amount_minor = 0
      and v_receivable_create_amount_minor = 0 then 'refund'
    when v_receivable_create_amount_minor > 0
      and v_collect_amount_minor = 0
      and v_refund_amount_minor = 0
      and v_receivable_reverse_amount_minor = 0 then 'receivable_offset'
    when v_receivable_reverse_amount_minor > 0
      and v_refund_amount_minor = 0
      and v_collect_amount_minor = 0
      and v_receivable_create_amount_minor = 0 then 'receivable_offset'
    else 'mixed'
  end;
```

3. Thay câu upsert (từ `  insert into sales.return_exchange_valuations (` tới `  returning id into v_valuation_id;`) bằng:

```sql
  insert into sales.return_exchange_valuations (
    id,
    tenant_id,
    return_exchange_order_id,
    currency_code,
    return_value_minor,
    exchange_value_minor,
    net_difference_minor,
    status,
    valuation_details,
    calculated_at
  ) values (
    gen_random_uuid(),
    evaluate_return_exchange_valuation.tenant_id,
    v_session.id,
    v_currency,
    v_return_value_minor,
    v_exchange_value_minor,
    v_net_difference_minor,
    'calculated',
    v_details,
    now()
  )
  on conflict (return_exchange_order_id) do update
  set
    currency_code = excluded.currency_code,
    return_value_minor = excluded.return_value_minor,
    exchange_value_minor = excluded.exchange_value_minor,
    net_difference_minor = excluded.net_difference_minor,
    status = 'calculated',
    valuation_details = excluded.valuation_details,
    calculated_at = now()
  returning id into v_valuation_id;
```

- [ ] **Step 5: Sửa `settle_return_exchange_difference` (`20260830013`)**

```sql
-- trước
    status = case
      when status = 'calculated' then 'confirmed'
      else status
    end,
    confirmed_at = coalesce(confirmed_at, now()),
    version = version + 1,
    updated_at = now()
  where id = v_valuation.id;
-- sau
    status = case
      when status = 'calculated' then 'confirmed'
      else status
    end
  where id = v_valuation.id;
```

- [ ] **Step 6: Sửa `confirm_return_exchange` (`20260904001`)**

```sql
-- trước
  update sales.return_exchange_valuations
  set
    status = 'confirmed',
    confirmed_at = coalesce(confirmed_at, now()),
    updated_at = now()
  where id = v_valuation.id;
-- sau
  update sales.return_exchange_valuations
  set status = 'confirmed'
  where id = v_valuation.id;
```

- [ ] **Step 7: Chạy test, xác nhận pass**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_14_return_exchange_valuations_sql_contract_test.dart test/domain/schema/sales_refactor_13_return_exchange_lines_sql_contract_test.dart`
Expected: PASS (các test baseline trong `sales_return_exchange_group_i_settlement_sql_contract_test.dart` vẫn fail như trước).

- [ ] **Step 8: Grep + policy + toàn bộ test**
- `grep -nE "required_settlement_type|calculated_by_user_id|return_exchange_valuations\.version" supabase/migrations/*.sql` → chỉ còn trong bản cũ `confirm_return_exchange` của `014` (nếu có).
- `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart --strict` → OK.
- `cd modules/sales/infrastructure && dart test` → chỉ còn baseline fail.

- [ ] **Step 9: Tiến độ spec** — dòng bảng 14 README: `✅ Đã chốt · bỏ 5 cột chỉ-ghi, bỏ superseded · 📝 Plan … · 🧪 Đã sửa migration gốc, chờ reset`.

- [ ] **Step 10: Tóm tắt + đề xuất commit, dừng — user reset + smoke test**

Đề xuất commit: `refactor(sales): drop write-only return/exchange valuation columns`

Sau `supabase db reset`:
1. Đổi trả có khách trả thêm → định giá hiện đúng giá trị trả/đổi/chênh lệch; sửa dòng → định giá lại ghi đè đúng.
2. Xác nhận + thu chênh lệch → thành công; đổi trả có hoàn tiền → thành công.
3. SQL Editor: `select status, return_value_minor, exchange_value_minor, net_difference_minor, calculated_at from sales.return_exchange_valuations order by created_at desc limit 5;` → phiếu đã xác nhận có `status = 'confirmed'`.
