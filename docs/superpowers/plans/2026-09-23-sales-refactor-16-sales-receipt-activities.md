# Sales refactor — Bảng 16 `sales.sales_receipt_activities` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bỏ 5 cột không dùng của `sales.sales_receipt_activities` và đổi `actor_user_id` sang `not null` — **sửa trực tiếp migration gốc**.

**Architecture:** Chỉ sửa `create table` trong `20260830005`. Câu insert duy nhất (`record_sales_receipt_activity`, `20260830010`) đã chỉ ghi các cột được giữ → không đổi hàm.

**Tech Stack:** PostgreSQL/Supabase; Dart `package:test`.

**Spec:** [16-sales-receipt-activities.md](../specs/sales-schema-refactor/16-sales-receipt-activities.md) · Quy ước: [README §Quy ước implement](../specs/sales-schema-refactor/README.md#quy-ước-implement-sửa-trực-tiếp-migration-gốc)

## Global Constraints

- Tuân thủ **Quy ước implement**. Thứ tự: sau plan 15.
- Không sửa `record_sales_receipt_activity`.
- Không `dart format` cả package; chỉ file test mới.
- **Không `git commit`** — cuối task tóm tắt + đề xuất commit rồi dừng.

## Khảo sát

| Vị trí | Nội dung |
|---|---|
| `20260830005` `create table if not exists sales.sales_receipt_activities` | `actor_user_id uuid` (nullable), `channel`, `destination_masked`, `device_context`, `activity_metadata`, `created_at` |
| `20260830010` `record_sales_receipt_activity` | `insert into sales.sales_receipt_activities (id, tenant_id, sales_receipt_id, actor_user_id, activity_type, occurred_at)` với `p_actor_id` (đã qua `_assert_sales_actor`) |
| Test | `sales_rebuild_schema_sql_contract_test.dart` (tên bảng — vẫn pass); 2 test baseline kiểm tra câu insert — không đổi |

## File Structure

| File | Thay đổi |
|---|---|
| Modify `supabase/migrations/20260830005_sales_rebuild_schema.sql` | `create table` |
| Create `modules/sales/infrastructure/test/domain/schema/sales_refactor_16_receipt_activities_sql_contract_test.dart` | SQL contract test |
| Modify `docs/superpowers/specs/sales-schema-refactor/README.md` | Tiến độ |

---

### Task 1: Rút gọn bảng hoạt động hoá đơn

- [ ] **Step 1: Viết test (fail)**

```dart
import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Sales refactor bảng 16 `sales.sales_receipt_activities`
/// (docs/superpowers/specs/sales-schema-refactor/16-sales-receipt-activities.md).
void main() {
  final schemaSql = _readMigration('20260830005_sales_rebuild_schema.sql');

  test('receipt activities keep 6 columns with required actor', () {
    final start = schemaSql.indexOf(
      'create table if not exists sales.sales_receipt_activities (',
    );
    final table = schemaSql.substring(start, schemaSql.indexOf('\n);', start));
    for (final column in [
      'channel',
      'destination_masked',
      'device_context',
      'activity_metadata',
      'created_at',
    ]) {
      expect(table, isNot(contains(column)), reason: column);
    }
    expect(table, contains('actor_user_id uuid not null,'));
    expect(table, contains('occurred_at timestamptz not null default now(),'));
    expect(table, contains("check (activity_type in ('printed', 'shared', 'archived'))"));
  });

  test('activity insert still writes exactly the kept columns', () {
    final receiptSql = _readMigration('20260830010_sales_inquiry_receipt_rpcs.sql');
    expect(
      receiptSql,
      contains(
        'insert into sales.sales_receipt_activities (\n'
        '    id, tenant_id, sales_receipt_id, actor_user_id, activity_type, occurred_at\n'
        '  )',
      ),
    );
  });
}

String _readMigration(String fileName) {
  final root = _findRepoRoot();
  return File('${root.path}/supabase/migrations/$fileName').readAsStringSync();
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

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_16_receipt_activities_sql_contract_test.dart`
Expected: FAIL test đầu (test thứ hai đã pass).

- [ ] **Step 3: Sửa `create table` trong `20260830005`** — thay cả khối bằng:

```sql
create table if not exists sales.sales_receipt_activities (
  id uuid primary key,
  tenant_id uuid not null,
  sales_receipt_id uuid not null,
  actor_user_id uuid not null,
  activity_type text not null,
  occurred_at timestamptz not null default now(),
  constraint sales_receipt_activities_type_check
    check (activity_type in ('printed', 'shared', 'archived')),
  constraint sales_receipt_activities_parent_fk
    foreign key (tenant_id, sales_receipt_id)
    references sales.sales_receipts (tenant_id, id) on delete cascade           -- FC-01
);
```

- [ ] **Step 4: Chạy test, xác nhận pass**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_16_receipt_activities_sql_contract_test.dart test/domain/schema/sales_rebuild_schema_sql_contract_test.dart`
Expected: PASS.

- [ ] **Step 5: Policy + toàn bộ test**
- `grep -nE "destination_masked|device_context|activity_metadata" supabase/migrations/*.sql` → không còn kết quả.
- `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart --strict` → OK.
- `cd modules/sales/infrastructure && dart test` → chỉ còn baseline fail.

- [ ] **Step 6: Tiến độ spec** — dòng bảng 16 README: `✅ Đã chốt · bỏ 5 cột, actor not null · 📝 Plan … · 🧪 Đã sửa migration gốc, chờ reset`.

- [ ] **Step 7: Tóm tắt + đề xuất commit, dừng — user reset + smoke test**

Đề xuất commit: `refactor(sales): drop unused receipt activity columns`

Sau `supabase db reset`: in, chia sẻ, lưu trữ một hoá đơn → SQL Editor `select activity_type, actor_user_id, occurred_at from sales.sales_receipt_activities order by occurred_at desc limit 5;` → 3 dòng, có người thao tác.
