# Sales refactor — Bảng 2 `sales.sales_order_number_counters` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bỏ cột `updated_at` của `sales.sales_order_number_counters`, sửa comment `period_key` và thêm comment cho `next_value` — **sửa trực tiếp migration gốc**.

**Architecture:** Một task: sửa `create table` trong `20260830005` và câu upsert bộ đếm trong `sales.finalize_sales_order` (`20260830008`, file owner duy nhất). Mã đơn và contract RPC không đổi.

**Tech Stack:** PostgreSQL/Supabase plpgsql; Dart `package:test`.

**Spec:** [02-sales-order-number-counters.md](../specs/sales-schema-refactor/02-sales-order-number-counters.md) · Quy ước: [README §Quy ước implement](../specs/sales-schema-refactor/README.md#quy-ước-implement-sửa-trực-tiếp-migration-gốc)

## Global Constraints

- Tuân thủ **Quy ước implement**. Thứ tự: sau plan 1 (cùng sửa `finalize_sales_order`; tìm theo nội dung, không theo số dòng).
- Giữ khoá `(tenant_id, store_id, period_key)` và tên cột `next_value`.
- Không `dart format` cả package; chỉ file test mới.
- **Không `git commit`** — cuối task tóm tắt + đề xuất commit rồi dừng.
- Trước khi sửa hàm: `node .gitnexus/run.cjs impact "finalize_sales_order" --direction upstream --repo .` (hàm SQL → `UNKNOWN`; đối chiếu khảo sát).

## Khảo sát

| Vị trí | Nội dung |
|---|---|
| `20260830005` `create table if not exists sales.sales_order_number_counters` | 5 cột; `period_key varchar(20) not null, -- e.g. yyyymm bucket per numbering policy`; `updated_at timestamptz not null default now()` |
| `20260830008` `finalize_sales_order` | `do update set next_value = sales.sales_order_number_counters.next_value + 1, updated_at = now()` |
| Nơi khác | Không migration/test nào khác tham chiếu bảng (đã grep `supabase/migrations`, `modules/sales`) |

## File Structure

| File | Thay đổi |
|---|---|
| Modify `supabase/migrations/20260830005_sales_rebuild_schema.sql` | `create table` bộ đếm |
| Modify `supabase/migrations/20260830008_sales_checkout_rpcs.sql` | Upsert trong `finalize_sales_order` |
| Create `modules/sales/infrastructure/test/domain/schema/sales_refactor_02_order_number_counters_sql_contract_test.dart` | SQL contract test |
| Modify `docs/superpowers/specs/sales-schema-refactor/README.md` | Tiến độ |

---

### Task 1: Bỏ `updated_at`, sửa comment

- [ ] **Step 1: Viết test (fail)**

```dart
import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Sales refactor bảng 2 `sales.sales_order_number_counters`
/// (docs/superpowers/specs/sales-schema-refactor/02-sales-order-number-counters.md).
void main() {
  final schemaSql = _readMigration('20260830005_sales_rebuild_schema.sql');
  final checkoutSql = _readMigration('20260830008_sales_checkout_rpcs.sql');

  test('counter table keeps store-scoped key without updated_at', () {
    final start = schemaSql.indexOf(
      'create table if not exists sales.sales_order_number_counters (',
    );
    final table = schemaSql.substring(start, schemaSql.indexOf('\n);', start));
    expect(table, contains('primary key (tenant_id, store_id, period_key)'));
    expect(table, contains('yyyymmdd'));
    expect(table, isNot(contains('yyyymm bucket')));
    expect(table, contains('last issued'));
    expect(table, isNot(contains('updated_at')));
  });

  test('finalize upsert no longer touches updated_at', () {
    final body = _lastFunctionBlock(checkoutSql, 'sales.finalize_sales_order');
    expect(
      body,
      contains(
        'do update set next_value = sales.sales_order_number_counters.next_value + 1\n',
      ),
    );
    expect(body, isNot(contains('next_value + 1, updated_at = now()')));
    expect(
      body,
      contains("v_order_code := 'DH' || v_period || lpad(v_seq_no::text, 4, '0');"),
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

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_02_order_number_counters_sql_contract_test.dart`
Expected: FAIL 2 test.

- [ ] **Step 3: Sửa `create table` trong `20260830005`** — thay cả khối (kèm comment ngay trên) bằng:

```sql
-- Infrastructure sequences (review §7.1 KEEP) — concurrency-safe reference-number sources.
create table if not exists sales.sales_order_number_counters (
  tenant_id uuid not null,
  store_id uuid not null,
  period_key varchar(20) not null,                 -- yyyymmdd, business date in Asia/Ho_Chi_Minh
  next_value bigint not null default 1,            -- last issued sequence number for the period
  primary key (tenant_id, store_id, period_key)
);
```

- [ ] **Step 4: Sửa upsert trong `finalize_sales_order` (`20260830008`)**

```sql
-- trước
      do update set next_value = sales.sales_order_number_counters.next_value + 1, updated_at = now()
-- sau
      do update set next_value = sales.sales_order_number_counters.next_value + 1
```

- [ ] **Step 5: Chạy test, xác nhận pass**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_02_order_number_counters_sql_contract_test.dart test/domain/schema/sales_rebuild_schema_sql_contract_test.dart test/domain/sales_order/sales_checkout_group_d_sql_contract_test.dart`
Expected: PASS.

- [ ] **Step 6: Grep + policy**
- `grep -n "sales_order_number_counters" supabase/migrations/*.sql` → chỉ còn `create table` + danh sách RLS trong `20260830005` và upsert trong `20260830008`; không dòng nào có `updated_at`.
- `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart --strict` → OK.

- [ ] **Step 7: Tiến độ spec** — dòng bảng 2 README: `✅ Đã chốt · bỏ updated_at, sửa comment · 📝 Plan … · 🧪 Đã sửa migration gốc, chờ reset`.

- [ ] **Step 8: Tóm tắt + đề xuất commit, dừng — user reset + smoke test**

Đề xuất commit: `refactor(sales): drop unused updated_at from order number counters`

Sau `supabase db reset`: thanh toán 2 đơn liên tiếp trong ngày → mã `DH<yyyymmdd>0001`, `DH<yyyymmdd>0002`. SQL Editor: `select * from sales.sales_order_number_counters;` → `next_value = 2`.
