# Sales refactor — Bảng 15 `sales.sales_receipts` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bỏ 7 cột không dùng/trùng của `sales.sales_receipts` cùng FK/CHECK/index/nhánh kiểm tra của `superseded_by_receipt_id` — **sửa trực tiếp migration gốc**, không đổi contract RPC.

**Architecture:** Bảng ở `20260830005`. Ghi ở `generate_sales_receipt` và `record_sales_receipt_activity` (`20260830010`, file owner duy nhất). Nhánh kiểm tra ở `audit_sales_review_invariants` (`20260830006`, `language sql` — bắt buộc sửa).

**Tech Stack:** PostgreSQL/Supabase plpgsql + sql; Dart `package:test`.

**Spec:** [15-sales-receipts.md](../specs/sales-schema-refactor/15-sales-receipts.md) · Quy ước: [README §Quy ước implement](../specs/sales-schema-refactor/README.md#quy-ước-implement-sửa-trực-tiếp-migration-gốc)

## Global Constraints

- Tuân thủ **Quy ước implement**. Thứ tự: sau plan 14 (plan 1, 6, 7, 9 cũng sửa `010`/`006`) — tìm theo nội dung.
- Giữ CHECK `status` 3 giá trị; giữ `sales_receipts_tenant_id_unique` (đích FK của `sales_receipt_activities`).
- Không sửa test baseline `sales_receipt_group_e_sql_contract_test.dart`, `sales_read_group_e_sql_contract_test.dart`.
- Không `dart format` cả package; chỉ file test mới.
- **Không `git commit`** — cuối task tóm tắt + đề xuất commit rồi dừng.
- Trước khi sửa hàm: `node .gitnexus/run.cjs impact "<tên hàm>" --direction upstream --repo .` cho `generate_sales_receipt`, `record_sales_receipt_activity`, `audit_sales_review_invariants` (hàm SQL → `UNKNOWN`; đối chiếu khảo sát).

## Khảo sát

| Vị trí | Nội dung |
|---|---|
| `20260830005` `create table if not exists sales.sales_receipts` | 15 cột; `sales_receipts_superseded_fk` (FK chỉ theo `id`) |
| `20260830005` khối SCHEMA EVOLUTION | `create unique index … sales_receipts_tenant_order_id_uidx`; cặp drop/drop/add `sales_receipts_superseded_same_order_fk`; cặp drop/add `sales_receipts_no_self_supersession` |
| `20260830010` `generate_sales_receipt` | insert có `template_code`, `template_version`, `generated_by_user_id`; update `set status = 'superseded', superseded_by_receipt_id = v_receipt.id … and id is distinct from superseded_by_receipt_id` |
| `20260830010` `record_sales_receipt_activity` | `set status = 'archived', archived_by_user_id = p_actor_id, archived_at = now()` |
| `20260830006` `audit_sales_review_invariants` | nhánh `'receipt_superseded_cross_order'` (join `successor` theo `superseded_by_receipt_id`) |
| `_sales_receipt_envelope` | chỉ đọc `id`, `sales_order_id`, `receipt_version`, `status`, `generated_at`, `receipt_snapshot` → không đổi |

## File Structure

| File | Thay đổi |
|---|---|
| Modify `supabase/migrations/20260830005_sales_rebuild_schema.sql` | `create table` + xoá index/alter cũ |
| Modify `supabase/migrations/20260830010_sales_inquiry_receipt_rpcs.sql` | `generate`, `record_activity` |
| Modify `supabase/migrations/20260830006_sales_shared_rpc_helpers.sql` | bỏ nhánh kiểm tra |
| Create `modules/sales/infrastructure/test/domain/schema/sales_refactor_15_receipts_sql_contract_test.dart` | SQL contract test |
| Modify `docs/superpowers/specs/sales-schema-refactor/README.md` | Tiến độ |

---

### Task 1: Bỏ 7 cột

- [ ] **Step 1: Viết test (fail)**

```dart
import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Sales refactor bảng 15 `sales.sales_receipts`
/// (docs/superpowers/specs/sales-schema-refactor/15-sales-receipts.md).
void main() {
  final schemaSql = _readMigration('20260830005_sales_rebuild_schema.sql');
  final receiptSql = _readMigration('20260830010_sales_inquiry_receipt_rpcs.sql');
  const removed = [
    'template_code',
    'template_version',
    'superseded_by_receipt_id',
    'archived_by_user_id',
    'archived_at',
    'generated_by_user_id',
    'created_at',
  ];

  test('receipts table keeps 8 columns and no supersession pointer', () {
    final start = schemaSql.indexOf('create table if not exists sales.sales_receipts (');
    final table = schemaSql.substring(start, schemaSql.indexOf('\n);', start));
    for (final column in removed) {
      expect(table, isNot(contains(column)), reason: column);
    }
    expect(table, contains('generated_at timestamptz not null default now(),'));
    expect(table, contains('constraint sales_receipts_tenant_id_unique'));
    expect(schemaSql, isNot(contains('alter table sales.sales_receipts')));
    expect(schemaSql, isNot(contains('sales_receipts_tenant_order_id_uidx')));
  });

  test('generate and archive write only kept columns', () {
    final generate = _lastFunctionBlock(receiptSql, 'sales.generate_sales_receipt');
    final insertStart = generate.indexOf('insert into sales.sales_receipts (');
    final insert = generate.substring(insertStart, generate.indexOf('returning * into v_receipt;', insertStart));
    for (final column in removed) {
      expect(insert, isNot(contains(column)), reason: column);
    }
    expect(generate, isNot(contains('superseded_by_receipt_id')));
    expect(generate, contains("set status = 'superseded'\n"));
    final activity = _lastFunctionBlock(receiptSql, 'sales.record_sales_receipt_activity');
    expect(activity, isNot(contains('archived_by_user_id')));
    expect(activity, isNot(contains('archived_at')));
    expect(activity, contains("set status = 'archived'\n"));
  });

  test('audit no longer checks the supersession pointer', () {
    final audit = _lastFunctionBlock(
      _readMigration('20260830006_sales_shared_rpc_helpers.sql'),
      'sales.audit_sales_review_invariants',
    );
    expect(audit, isNot(contains('receipt_superseded_cross_order')));
    expect(audit, isNot(contains('superseded_by_receipt_id')));
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

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_15_receipts_sql_contract_test.dart`
Expected: FAIL 3 test.

- [ ] **Step 3: Sửa `create table` trong `20260830005`** — thay cả khối bằng:

```sql
create table if not exists sales.sales_receipts (
  id uuid primary key,
  tenant_id uuid not null,
  sales_order_id uuid not null,
  receipt_version integer not null,
  status text not null,
  content_hash varchar(128) not null,
  receipt_snapshot jsonb not null,
  generated_at timestamptz not null default now(),
  constraint sales_receipts_version_unique unique (sales_order_id, receipt_version), -- FC-09
  constraint sales_receipts_status_check
    check (status in ('generated', 'superseded', 'archived')),
  constraint sales_receipts_parent_fk
    foreign key (tenant_id, sales_order_id)
    references sales.sales_orders (tenant_id, id),                             -- FC-01
  constraint sales_receipts_tenant_id_unique unique (tenant_id, id)
);
```

- [ ] **Step 4: Xoá khối cũ trong SCHEMA EVOLUTION (`20260830005`)** — xoá 3 đoạn (kèm dòng trống theo sau):

```sql
create unique index if not exists sales_receipts_tenant_order_id_uidx
  on sales.sales_receipts (tenant_id, sales_order_id, id);
```

```sql
alter table sales.sales_receipts
  drop constraint if exists sales_receipts_superseded_fk;
alter table sales.sales_receipts
  drop constraint if exists sales_receipts_superseded_same_order_fk;
alter table sales.sales_receipts
  add constraint sales_receipts_superseded_same_order_fk
  foreign key (tenant_id, sales_order_id, superseded_by_receipt_id)
  references sales.sales_receipts (tenant_id, sales_order_id, id);
```

```sql
alter table sales.sales_receipts
  drop constraint if exists sales_receipts_no_self_supersession;
alter table sales.sales_receipts
  add constraint sales_receipts_no_self_supersession
  check (id is distinct from superseded_by_receipt_id);
```

- [ ] **Step 5: Sửa `generate_sales_receipt` (`20260830010`)**

```sql
-- trước
  insert into sales.sales_receipts (
    id, tenant_id, sales_order_id, receipt_version, status,
    template_code, template_version, content_hash, receipt_snapshot,
    generated_by_user_id, generated_at
  ) values (
    v_receipt_id, p_tenant_id, p_sales_order_id, v_next_version, 'generated',
    'sales_receipt_default', '1', md5(v_snapshot::text),
    v_snapshot, p_actor_id, now()
  ) returning * into v_receipt;

  update sales.sales_receipts
  set status = 'superseded',
      superseded_by_receipt_id = v_receipt.id
  where tenant_id = p_tenant_id
    and sales_order_id = p_sales_order_id
    and status = 'generated'
    and id is distinct from v_receipt.id
    and id is distinct from superseded_by_receipt_id;
-- sau
  insert into sales.sales_receipts (
    id, tenant_id, sales_order_id, receipt_version, status,
    content_hash, receipt_snapshot, generated_at
  ) values (
    v_receipt_id, p_tenant_id, p_sales_order_id, v_next_version, 'generated',
    md5(v_snapshot::text), v_snapshot, now()
  ) returning * into v_receipt;

  update sales.sales_receipts
  set status = 'superseded'
  where tenant_id = p_tenant_id
    and sales_order_id = p_sales_order_id
    and status = 'generated'
    and id is distinct from v_receipt.id;
```

- [ ] **Step 6: Sửa `record_sales_receipt_activity` (`20260830010`)**

```sql
-- trước
    update sales.sales_receipts
    set status = 'archived',
        archived_by_user_id = p_actor_id,
        archived_at = now()
    where id = v_receipt.id
-- sau
    update sales.sales_receipts
    set status = 'archived'
    where id = v_receipt.id
```

- [ ] **Step 7: Sửa `audit_sales_review_invariants` (`20260830006`)** — xoá nguyên nhánh (từ `  union all` ngay trước `    'receipt_superseded_cross_order',` tới hết `     or receipt.id = receipt.superseded_by_receipt_id`, kèm dòng trống theo sau):

```sql
  union all
  select
    'receipt_superseded_cross_order',
    receipt.tenant_id,
    receipt.sales_order_id,
    receipt.id,
    'not_applicable',
    receipt.superseded_by_receipt_id::text,
    null,
    'successor must share tenant and order; do not rewrite'
  from sales.sales_receipts receipt
  join sales.sales_receipts successor
    on successor.id = receipt.superseded_by_receipt_id
  where receipt.tenant_id is distinct from successor.tenant_id
     or receipt.sales_order_id is distinct from successor.sales_order_id
     or receipt.id = receipt.superseded_by_receipt_id
```

(Nhánh `'return_source_xor'` ngay sau vẫn bắt đầu bằng `  union all` → câu lệnh vẫn hợp lệ.)

- [ ] **Step 8: Chạy test, xác nhận pass**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_15_receipts_sql_contract_test.dart test/domain/schema/sales_refactor_06_order_lines_sql_contract_test.dart test/domain/schema/sales_shared_rpc_helpers_sql_contract_test.dart`
Expected: PASS.

- [ ] **Step 9: Grep + policy + toàn bộ test**
- `grep -nE "superseded_by_receipt_id|template_code|archived_by_user_id|generated_by_user_id|sales_receipts_tenant_order_id_uidx" supabase/migrations/*.sql` → không còn kết quả.
- `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart --strict` → OK.
- `cd modules/sales/infrastructure && dart test` → chỉ còn baseline fail.

- [ ] **Step 10: Tiến độ spec** — dòng bảng 15 README: `✅ Đã chốt · bỏ 7 cột + FK/CHECK/index supersession · 📝 Plan … · 🧪 Đã sửa migration gốc, chờ reset`.

- [ ] **Step 11: Tóm tắt + đề xuất commit, dừng — user reset + smoke test**

Đề xuất commit: `refactor(sales): drop unused receipt columns and supersession pointer`

Sau `supabase db reset`:
1. Tạo hoá đơn cho 1 đơn → xem hoá đơn: số phiếu, nội dung, thời điểm tạo đúng.
2. Tạo lại hoá đơn lần 2 → bản mới `version = 2`, bản cũ `superseded`.
3. In, chia sẻ, lưu trữ hoá đơn → thành công; bản lưu trữ có `status = 'archived'`.
4. SQL Editor: `select receipt_version, status, generated_at from sales.sales_receipts order by generated_at desc limit 5;`
