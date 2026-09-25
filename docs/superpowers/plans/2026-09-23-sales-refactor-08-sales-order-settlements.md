# Sales refactor — Bảng 8 `sales.sales_order_settlements` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bỏ `reconciliation_status` và `last_transaction_at` của `sales.sales_order_settlements`, gộp alter cũ của bảng vào `create table` — **sửa trực tiếp migration gốc**, không đổi contract RPC.

**Architecture:** Bảng ở `20260830005`. Chỉ 2 hàm tham chiếu cột bỏ: `finalize_sales_order` (`20260830008`, insert) và `_recompute_sales_settlement` (`20260830006`, file owner duy nhất).

**Tech Stack:** PostgreSQL/Supabase plpgsql; Dart `package:test`.

**Spec:** [08-sales-order-settlements.md](../specs/sales-schema-refactor/08-sales-order-settlements.md) · Quy ước: [README §Quy ước implement](../specs/sales-schema-refactor/README.md#quy-ước-implement-sửa-trực-tiếp-migration-gốc)

## Global Constraints

- Tuân thủ **Quy ước implement**. Thứ tự: sau plan 7 (plan 1–3, 5, 6 cùng sửa `finalize_sales_order`) — tìm theo nội dung.
- Giữ `settled_at` và cách tính hiện tại của nó.
- Không sửa draft theme8 (`017`).
- Không `dart format` cả package; chỉ file test mới.
- **Không `git commit`** — cuối task tóm tắt + đề xuất commit rồi dừng.
- Trước khi sửa hàm: `node .gitnexus/run.cjs impact "_recompute_sales_settlement" --direction upstream --repo .` và `… "finalize_sales_order" …` (hàm SQL → `UNKNOWN`; đối chiếu khảo sát).

## Khảo sát

| Vị trí | Nội dung |
|---|---|
| `20260830005` `create table if not exists sales.sales_order_settlements` | `reconciliation_status text not null default 'not_required'`, `last_transaction_at timestamptz`, `constraint sales_settlements_recon_status_check` |
| `20260830005` khối SCHEMA EVOLUTION | cặp `drop/add constraint sales_settlements_payment_status_check` (giống hệt constraint trong `create table`) |
| `20260830008` `finalize_sales_order` | insert settlement: `payment_status, reconciliation_status, last_transaction_at, settled_at` / `v_payment_status, 'not_required', case when v_paid_total_minor > 0 then now() else null end, case … settled_at …` |
| `20260830006` `_recompute_sales_settlement` | `v_last timestamptz;`, `max(confirmed_at)` → `v_last`, `last_transaction_at = v_last,` |
| Nơi khác | Không migration/test nào khác; theme8 chỉ draft `017` (ghi ở README "Việc phát sinh") |

## File Structure

| File | Thay đổi |
|---|---|
| Modify `supabase/migrations/20260830005_sales_rebuild_schema.sql` | `create table` + xoá alter cũ |
| Modify `supabase/migrations/20260830008_sales_checkout_rpcs.sql` | insert settlement |
| Modify `supabase/migrations/20260830006_sales_shared_rpc_helpers.sql` | `_recompute_sales_settlement` |
| Create `modules/sales/infrastructure/test/domain/schema/sales_refactor_08_settlements_sql_contract_test.dart` | SQL contract test |
| Modify `docs/superpowers/specs/sales-schema-refactor/README.md` | Tiến độ |

---

### Task 1: Bỏ `reconciliation_status`, `last_transaction_at`

- [ ] **Step 1: Viết test (fail)**

```dart
import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Sales refactor bảng 8 `sales.sales_order_settlements`
/// (docs/superpowers/specs/sales-schema-refactor/08-sales-order-settlements.md).
void main() {
  final schemaSql = _readMigration('20260830005_sales_rebuild_schema.sql');
  const removed = ['reconciliation_status', 'last_transaction_at'];

  test('settlement table drops unused columns and keeps settled_at', () {
    final start = schemaSql.indexOf(
      'create table if not exists sales.sales_order_settlements (',
    );
    final table = schemaSql.substring(start, schemaSql.indexOf('\n);', start));
    for (final column in removed) {
      expect(table, isNot(contains(column)), reason: column);
    }
    expect(table, isNot(contains('sales_settlements_recon_status_check')));
    expect(table, contains('settled_at timestamptz,'));
    expect(table, contains("'partially_refunded', 'refunded', 'no_balance'"));
    expect(schemaSql, isNot(contains('alter table sales.sales_order_settlements')));
  });

  test('finalize settlement insert omits removed columns', () {
    final checkoutSql = _readMigration('20260830008_sales_checkout_rpcs.sql');
    final finalize = _lastFunctionBlock(checkoutSql, 'sales.finalize_sales_order');
    final start = finalize.indexOf('insert into sales.sales_order_settlements(');
    final insert = finalize.substring(start, finalize.indexOf('    );', start));
    for (final column in removed) {
      expect(insert, isNot(contains(column)), reason: column);
    }
    expect(insert, isNot(contains("'not_required'")));
    expect(insert, contains('payment_status, settled_at'));
  });

  test('recompute no longer tracks last_transaction_at', () {
    final helperSql = _readMigration('20260830006_sales_shared_rpc_helpers.sql');
    final recompute = _lastFunctionBlock(helperSql, 'sales._recompute_sales_settlement');
    expect(recompute, isNot(contains('last_transaction_at')));
    expect(recompute, isNot(contains('v_last')));
    expect(recompute, isNot(contains('max(confirmed_at)')));
    expect(recompute, contains('then coalesce(settled_at, now())'));
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

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_08_settlements_sql_contract_test.dart`
Expected: FAIL 3 test.

- [ ] **Step 3: Sửa `create table` trong `20260830005`** — thay cả khối bằng:

```sql
create table if not exists sales.sales_order_settlements (
  id uuid primary key,
  tenant_id uuid not null,
  sales_order_id uuid not null,
  currency_code char(3) not null,
  original_payable_amount_minor bigint not null,
  post_sale_adjustment_amount_minor bigint not null default 0,                 -- signed
  current_payable_amount_minor bigint not null,
  collected_amount_minor bigint not null default 0,
  refunded_amount_minor bigint not null default 0,
  net_collected_amount_minor bigint not null default 0,
  outstanding_amount_minor bigint not null,
  payment_status text not null,
  version bigint not null default 1,
  settled_at timestamptz,                                                      -- when fully paid; cleared if no longer settled
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint sales_settlements_order_unique unique (sales_order_id),            -- FC-07 (1:1)
  constraint sales_settlements_payment_status_check
    check (payment_status in ('unpaid', 'partially_paid', 'paid',
      'partially_refunded', 'refunded', 'no_balance')),
  constraint sales_settlements_current_payable_formula
    check (current_payable_amount_minor
      = original_payable_amount_minor + post_sale_adjustment_amount_minor),     -- FC-15
  constraint sales_settlements_net_collected_formula
    check (net_collected_amount_minor
      = collected_amount_minor - refunded_amount_minor),                        -- FC-16
  constraint sales_settlements_order_fk
    foreign key (tenant_id, sales_order_id)
    references sales.sales_orders (tenant_id, id),                              -- FC-01
  constraint sales_settlements_tenant_id_unique unique (tenant_id, id)
);
```

- [ ] **Step 4: Xoá alter cũ trong khối SCHEMA EVOLUTION (`20260830005`)** — xoá đoạn (kèm dòng trống theo sau):

```sql
alter table sales.sales_order_settlements
  drop constraint if exists sales_settlements_payment_status_check;
alter table sales.sales_order_settlements
  add constraint sales_settlements_payment_status_check
  check (payment_status in ('unpaid', 'partially_paid', 'paid',
    'partially_refunded', 'refunded', 'no_balance'));
```

- [ ] **Step 5: Sửa insert settlement trong `finalize_sales_order` (`20260830008`)**

```sql
-- trước
      refunded_amount_minor, net_collected_amount_minor, outstanding_amount_minor,
      payment_status, reconciliation_status, last_transaction_at, settled_at
    ) values (
      v_settlement_id, p_tenant_id, v_order_id, v_currency_code, v_grand_total_minor,
      0, v_grand_total_minor, v_paid_total_minor, 0, v_paid_total_minor, v_remaining_minor,
      v_payment_status, 'not_required',
      case when v_paid_total_minor > 0 then now() else null end,
      case when v_remaining_minor = 0 and v_paid_total_minor > 0 then now() else null end
    );
-- sau
      refunded_amount_minor, net_collected_amount_minor, outstanding_amount_minor,
      payment_status, settled_at
    ) values (
      v_settlement_id, p_tenant_id, v_order_id, v_currency_code, v_grand_total_minor,
      0, v_grand_total_minor, v_paid_total_minor, 0, v_paid_total_minor, v_remaining_minor,
      v_payment_status,
      case when v_remaining_minor = 0 and v_paid_total_minor > 0 then now() else null end
    );
```

- [ ] **Step 6: Sửa `_recompute_sales_settlement` (`20260830006`)**

1. `declare`: xoá dòng `  v_last timestamptz;`.
2. Câu select:

```sql
-- trước
  select
    coalesce(sum(amount_minor) filter (where direction = 'inflow' and status = 'confirmed'), 0),
    coalesce(sum(amount_minor) filter (where direction = 'outflow' and status = 'confirmed'), 0),
    max(confirmed_at)
  into v_collected, v_refunded, v_last
-- sau
  select
    coalesce(sum(amount_minor) filter (where direction = 'inflow' and status = 'confirmed'), 0),
    coalesce(sum(amount_minor) filter (where direction = 'outflow' and status = 'confirmed'), 0)
  into v_collected, v_refunded
```

3. Trong câu update: xoá dòng `      last_transaction_at = v_last,`.

- [ ] **Step 7: Chạy test, xác nhận pass**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_08_settlements_sql_contract_test.dart test/domain/schema/sales_shared_rpc_helpers_sql_contract_test.dart test/domain/sales_order/sales_checkout_group_d_sql_contract_test.dart`
Expected: PASS.

- [ ] **Step 8: Grep + policy + toàn bộ test**
- `grep -nE "reconciliation_status|last_transaction_at" supabase/migrations/*.sql` → không còn kết quả.
- `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart --strict` → OK.
- `cd modules/sales/infrastructure && dart test` → chỉ còn baseline fail.

- [ ] **Step 9: Tiến độ spec** — dòng bảng 8 README: `✅ Đã chốt · bỏ reconciliation_status, last_transaction_at · 📝 Plan … · 🧪 Đã sửa migration gốc, chờ reset`.

- [ ] **Step 10: Tóm tắt + đề xuất commit, dừng — user reset + smoke test**

Đề xuất commit: `refactor(sales): drop unused reconciliation and last-transaction columns from settlements`

Sau `supabase db reset`:
1. Thanh toán đơn trả đủ → trạng thái "Đã thanh toán"; `settled_at` có giá trị.
2. Thanh toán đơn khách quen trả một phần (có hạn thanh toán) → "Thanh toán một phần"; thu thêm cho đủ → "Đã thanh toán".
3. Hoàn tiền một phần → trạng thái cập nhật; huỷ đơn → "Không còn phải thu".
4. SQL Editor: `select payment_status, collected_amount_minor, refunded_amount_minor, outstanding_amount_minor, settled_at from sales.sales_order_settlements order by created_at desc limit 5;`
