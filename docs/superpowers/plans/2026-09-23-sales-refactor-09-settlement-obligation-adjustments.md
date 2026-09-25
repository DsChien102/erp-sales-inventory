# Sales refactor — Bảng 9 `sales.settlement_obligation_adjustments` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Chuyển `create table sales.settlement_obligation_adjustments` từ khối SCHEMA EVOLUTION lên phần SALES SETTLEMENT và thêm kiểm tra cân đối tổng điều chỉnh vào `audit_sales_review_invariants` — **sửa trực tiếp migration gốc**, không đổi cấu trúc bảng, không đổi contract RPC.

**Architecture:** `20260830005`: di chuyển nguyên khối `create table`. `20260830006`: thêm một nhánh `union all` vào `audit_sales_review_invariants` (`language sql`, chạy sau `005` nên bảng đã tồn tại).

**Tech Stack:** PostgreSQL/Supabase sql; Dart `package:test`.

**Spec:** [09-settlement-obligation-adjustments.md](../specs/sales-schema-refactor/09-settlement-obligation-adjustments.md) · Quy ước: [README §Quy ước implement](../specs/sales-schema-refactor/README.md#quy-ước-implement-sửa-trực-tiếp-migration-gốc)

## Global Constraints

- Tuân thủ **Quy ước implement**. Thứ tự: sau plan 8 (plan 7 đã thay nhánh cuối của `audit_sales_review_invariants`) — tìm theo nội dung.
- Không đổi cột/constraint của bảng.
- Không `dart format` cả package; chỉ file test mới.
- **Không `git commit`** — cuối task tóm tắt + đề xuất commit rồi dừng.
- Trước khi sửa hàm: `node .gitnexus/run.cjs impact "audit_sales_review_invariants" --direction upstream --repo .` (hàm SQL → `UNKNOWN`; hàm chỉ để đối soát thủ công, không RPC nào gọi).

## Khảo sát

| Vị trí | Nội dung |
|---|---|
| `20260830005` khối SCHEMA EVOLUTION (sau cặp alter `sales_settlements_payment_status_check` — plan 8 đã xoá cặp này) | `create table if not exists sales.settlement_obligation_adjustments (…);` |
| `20260830005` phần SALES SETTLEMENT | `create table … sales_order_settlements (…);` rồi `create table … sales_payment_transactions (` |
| `20260830006` `audit_sales_review_invariants` | `returns table (rule_code, tenant_id, sales_order_id, source_id, recoverability, current_value, proposed_value, basis)`; nhánh cuối (sau plan 7) bắt đầu `  union all` / `  select` / `    'return_projection_status_mismatch',` |
| RLS | danh sách bảng cuối `005` đã có `settlement_obligation_adjustments` → không đổi |

## File Structure

| File | Thay đổi |
|---|---|
| Modify `supabase/migrations/20260830005_sales_rebuild_schema.sql` | Di chuyển `create table` |
| Modify `supabase/migrations/20260830006_sales_shared_rpc_helpers.sql` | Thêm nhánh kiểm tra |
| Create `modules/sales/infrastructure/test/domain/schema/sales_refactor_09_obligation_adjustments_sql_contract_test.dart` | SQL contract test |
| Modify `docs/superpowers/specs/sales-schema-refactor/README.md` | Tiến độ |

---

### Task 1: Di chuyển bảng + kiểm tra cân đối

- [ ] **Step 1: Viết test (fail)**

```dart
import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Sales refactor bảng 9
/// `sales.settlement_obligation_adjustments`
/// (docs/superpowers/specs/sales-schema-refactor/09-settlement-obligation-adjustments.md).
void main() {
  final schemaSql = _readMigration('20260830005_sales_rebuild_schema.sql');

  test('adjustments table lives in the settlement section', () {
    final settlements = schemaSql.indexOf(
      'create table if not exists sales.sales_order_settlements (',
    );
    final adjustments = schemaSql.indexOf(
      'create table if not exists sales.settlement_obligation_adjustments (',
    );
    final payments = schemaSql.indexOf(
      'create table if not exists sales.sales_payment_transactions (',
    );
    final evolution = schemaSql.indexOf('SCHEMA EVOLUTION');
    expect(adjustments, greaterThan(settlements));
    expect(adjustments, lessThan(payments));
    expect(adjustments, lessThan(evolution));
    expect(
      'create table if not exists sales.settlement_obligation_adjustments ('
          .allMatches(schemaSql)
          .length,
      1,
    );
  });

  test('audit checks adjustment ledger sum against settlement', () {
    final helperSql = _readMigration('20260830006_sales_shared_rpc_helpers.sql');
    final audit = _lastFunctionBlock(helperSql, 'sales.audit_sales_review_invariants');
    expect(audit, contains("'settlement_adjustment_sum_mismatch'"));
    expect(audit, contains('from sales.settlement_obligation_adjustments adjustment'));
    expect(
      audit,
      contains(
        'where settlement.post_sale_adjustment_amount_minor\n'
        '    is distinct from coalesce(ledger.total_minor, 0)',
      ),
    );
    expect(
      audit.indexOf("'settlement_adjustment_sum_mismatch'"),
      lessThan(audit.indexOf("'return_projection_status_mismatch'")),
    );
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

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_09_obligation_adjustments_sql_contract_test.dart`
Expected: FAIL 2 test.

- [ ] **Step 3: Di chuyển `create table` trong `20260830005`**

1. Xoá khối sau khỏi khối SCHEMA EVOLUTION (kèm dòng trống theo sau):

```sql
create table if not exists sales.settlement_obligation_adjustments (
  id uuid primary key,
  tenant_id uuid not null,
  sales_order_settlement_id uuid not null,
  source_kind text not null
    check (source_kind in ('cancellation', 'return_exchange')),
  source_id uuid not null,
  amount_minor bigint not null,
  created_at timestamptz not null default now(),
  constraint settlement_obligation_adjustments_source_unique
    unique (tenant_id, source_kind, source_id),
  constraint settlement_obligation_adjustments_settlement_fk
    foreign key (tenant_id, sales_order_settlement_id)
    references sales.sales_order_settlements (tenant_id, id)
);
```

2. Chèn đúng khối đó (thêm 1 dòng comment ở đầu) ngay sau `);` kết thúc `create table … sales_order_settlements`, trước `create table if not exists sales.sales_payment_transactions (`:

```sql
-- Obligation ledger: one signed adjustment per post-sale source (cancellation / return-exchange).
create table if not exists sales.settlement_obligation_adjustments (
  id uuid primary key,
  tenant_id uuid not null,
  sales_order_settlement_id uuid not null,
  source_kind text not null
    check (source_kind in ('cancellation', 'return_exchange')),
  source_id uuid not null,
  amount_minor bigint not null,
  created_at timestamptz not null default now(),
  constraint settlement_obligation_adjustments_source_unique
    unique (tenant_id, source_kind, source_id),
  constraint settlement_obligation_adjustments_settlement_fk
    foreign key (tenant_id, sales_order_settlement_id)
    references sales.sales_order_settlements (tenant_id, id)
);
```

- [ ] **Step 4: Thêm nhánh vào `audit_sales_review_invariants` (`20260830006`)** — chèn ngay trước khối `  union all` / `  select` / `    'return_projection_status_mismatch',`:

```sql
  union all
  select
    'settlement_adjustment_sum_mismatch',
    settlement.tenant_id,
    settlement.sales_order_id,
    settlement.id,
    'recomputable_from_adjustment_ledger',
    settlement.post_sale_adjustment_amount_minor::text,
    coalesce(ledger.total_minor, 0)::text,
    'post_sale_adjustment_amount_minor must equal sum of settlement_obligation_adjustments'
  from sales.sales_order_settlements settlement
  left join lateral (
    select sum(adjustment.amount_minor) as total_minor
    from sales.settlement_obligation_adjustments adjustment
    where adjustment.tenant_id = settlement.tenant_id
      and adjustment.sales_order_settlement_id = settlement.id
  ) ledger on true
  where settlement.post_sale_adjustment_amount_minor
    is distinct from coalesce(ledger.total_minor, 0)

```

- [ ] **Step 5: Chạy test, xác nhận pass**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_09_obligation_adjustments_sql_contract_test.dart test/domain/schema/sales_refactor_07_return_status_projections_sql_contract_test.dart test/domain/schema/sales_shared_rpc_helpers_sql_contract_test.dart test/domain/schema/sales_rebuild_schema_sql_contract_test.dart`
Expected: PASS.

- [ ] **Step 6: Policy + toàn bộ test**
- `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart --strict` → OK.
- `cd modules/sales/infrastructure && dart test` → chỉ còn baseline fail.

- [ ] **Step 7: Tiến độ spec** — dòng bảng 9 README: `✅ Đã chốt · giữ nguyên cột, chuyển vị trí create, thêm kiểm tra cân đối · 📝 Plan … · 🧪 Đã sửa migration gốc, chờ reset`.

- [ ] **Step 8: Tóm tắt + đề xuất commit, dừng — user reset + smoke test**

Đề xuất commit: `refactor(sales): move obligation ledger into settlement section and audit its sum`

Sau `supabase db reset`:
1. Huỷ 1 đơn; đổi trả 1 đơn khác có chênh lệch.
2. Tạo hoá đơn cho 2 đơn → mục điều chỉnh (`adjustmentSources`) hiện đúng nguồn và số tiền.
3. SQL Editor: `select * from sales.audit_sales_review_invariants();` → không có dòng `settlement_adjustment_sum_mismatch`.
