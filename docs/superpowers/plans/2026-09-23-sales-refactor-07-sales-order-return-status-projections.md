# Sales refactor — Bảng 7 `sales.sales_order_return_status_projections` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rút gọn bảng phụ trạng thái trả hàng còn 4 cột (PK `(tenant_id, sales_order_id)`), thay nhánh kiểm tra số lượng trong `audit_sales_review_invariants` bằng kiểm tra trạng thái, sự kiện `return_exchange_completed.v1` gửi tổng **số lượng gốc** thay cho tổng trộn đơn vị, `complete_return_exchange` tính trạng thái theo từng dòng — **sửa trực tiếp migration gốc**, không đổi contract RPC.

**Architecture:** Bảng ở `20260830005`. Upsert ở `confirm_return_exchange` (định nghĩa cuối `20260904001`) và `complete_return_exchange` (`20260830014`). Hàm kiểm tra `audit_sales_review_invariants` (`language sql`, `20260830006`) được kiểm tra thân hàm lúc reset nên bắt buộc sửa. Biến `v_sold_micros`/`v_returned_micros` đổi tên thành `v_sold_base_micros`/`v_returned_base_micros` và chứa tổng `base_quantity_micros` cho payload sự kiện (Task 3).

**Tech Stack:** PostgreSQL/Supabase plpgsql + sql; Dart `package:test`.

**Spec:** [07-sales-order-return-status-projections.md](../specs/sales-schema-refactor/07-sales-order-return-status-projections.md) · Quy ước: [README §Quy ước implement](../specs/sales-schema-refactor/README.md#quy-ước-implement-sửa-trực-tiếp-migration-gốc)

## Global Constraints

- Tuân thủ **Quy ước implement**. Thứ tự: sau plan 6 (plan 1 cũng sửa `confirm_return_exchange`, `complete_return_exchange`) — tìm theo nội dung.
- Payload `return_exchange_completed.v1`: key `soldQuantityMicros`/`returnedQuantityMicros` đổi thành `soldBaseQuantityMicros`/`returnedBaseQuantityMicros` (tổng số lượng gốc; không có nơi tiêu thụ trên cả 2 nhánh). Các key khác giữ nguyên.
- Trạng thái trả hàng vẫn so theo từng dòng bằng `quantity_micros` (bảng 13 ⑦ ép dòng trả cùng đơn vị dòng nguồn).
- Không sửa bản cũ `confirm_return_exchange` trong `20260830014` (định nghĩa cuối ở `20260904001`).
- Không `dart format` cả package; chỉ file test mới.
- **Không `git commit`** — cuối mỗi task tóm tắt + đề xuất commit rồi dừng.
- Trước khi sửa hàm: `node .gitnexus/run.cjs impact "<tên hàm>" --direction upstream --repo .` cho `confirm_return_exchange`, `complete_return_exchange`, `audit_sales_review_invariants` (hàm SQL → `UNKNOWN`; đối chiếu khảo sát).

## Khảo sát

| Vị trí | Nội dung |
|---|---|
| `20260830005` `create table if not exists sales.sales_order_return_status_projections` | `id uuid primary key default gen_random_uuid()`, `sold_quantity_micros`, `returned_quantity_micros`, `version`, `unique (tenant_id, sales_order_id)` |
| `20260904001` `confirm_return_exchange` | upsert 7 cột (`… sold_quantity_micros, returned_quantity_micros, version, updated_at`) + `on conflict … set … version = … + 1` |
| `20260830014` `complete_return_exchange` | upsert giống hệt (tham số `complete_return_exchange.tenant_id`) |
| `20260830006` `audit_sales_review_invariants` (`language sql`) | nhánh cuối `'return_projection_quantity_mismatch'` so `projection.sold_quantity_micros`/`returned_quantity_micros` |
| Payload sự kiện | `'soldQuantityMicros', v_sold_micros, 'returnedQuantityMicros', v_returned_micros` ở cả 2 hàm — tổng `quantity_micros` trộn đơn vị → đổi (Task 3) |
| `20260904001` `confirm_return_exchange` tính trạng thái | CTE `with per_line as (select l.id, l.quantity_micros as sold_qty, coalesce((select sum(rl.quantity_micros) …), 0) as returned_qty …) select coalesce(sum(sold_qty), 0), coalesce(sum(returned_qty), 0), case … end into v_sold_micros, v_returned_micros, v_return_status from per_line;` |
| `20260830014` `complete_return_exchange` tính trạng thái | `select coalesce(sum(l.quantity_micros), 0) into v_sold_micros …; select coalesce(sum(rl.quantity_micros), 0) into v_returned_micros … and rl.line_role = 'returned';` + `v_return_status := case when v_returned_micros <= 0 … when v_returned_micros >= v_sold_micros … end;` (tổng gộp cả đơn, trộn đơn vị) |
| Nơi khác | `list_sales_orders`/`search_sales_orders` chỉ đọc `p.return_status` → không đổi. Không test nào tham chiếu cột bỏ; theme8 không dùng |

## File Structure

| File | Thay đổi |
|---|---|
| Modify `supabase/migrations/20260830005_sales_rebuild_schema.sql` | `create table` |
| Modify `supabase/migrations/20260904001_sales_normalize_outbox_and_commands.sql` | upsert trong `confirm_return_exchange` |
| Modify `supabase/migrations/20260830014_sales_return_exchange_confirmation_rpcs.sql` | upsert trong `complete_return_exchange` |
| Modify `supabase/migrations/20260830006_sales_shared_rpc_helpers.sql` | nhánh kiểm tra trong `audit_sales_review_invariants` |
| Create `modules/sales/infrastructure/test/domain/schema/sales_refactor_07_return_status_projections_sql_contract_test.dart` | SQL contract test |
| Modify `docs/superpowers/specs/sales-schema-refactor/README.md` | Tiến độ |

---

### Task 1: Bảng + 2 upsert

- [ ] **Step 1: Viết test (fail)**

```dart
import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Sales refactor bảng 7
/// `sales.sales_order_return_status_projections`
/// (docs/superpowers/specs/sales-schema-refactor/07-sales-order-return-status-projections.md).
void main() {
  final schemaSql = _readMigration('20260830005_sales_rebuild_schema.sql');
  const removed = ['sold_quantity_micros', 'returned_quantity_micros', 'version'];

  test('projection table keeps 4 columns with composite primary key', () {
    final start = schemaSql.indexOf(
      'create table if not exists sales.sales_order_return_status_projections (',
    );
    final table = schemaSql.substring(start, schemaSql.indexOf('\n);', start));
    expect(table, contains('primary key (tenant_id, sales_order_id)'));
    expect(table, isNot(contains('id uuid primary key')));
    for (final column in removed) {
      expect(table, isNot(contains(column)), reason: column);
    }
  });

  final upserts = <String, String>{
    '20260904001_sales_normalize_outbox_and_commands.sql': 'sales.confirm_return_exchange',
    '20260830014_sales_return_exchange_confirmation_rpcs.sql': 'sales.complete_return_exchange',
  };
  upserts.forEach((file, fn) {
    test('$fn upserts status only', () {
      final body = _lastFunctionBlock(_readMigration(file), fn);
      final start = body.indexOf(
        'insert into sales.sales_order_return_status_projections (',
      );
      final upsert = body.substring(start, body.indexOf('updated_at = now();', start));
      for (final column in removed) {
        expect(upsert, isNot(contains(column)), reason: column);
      }
      expect(upsert, contains('return_status = excluded.return_status,'));
    });
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

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_07_return_status_projections_sql_contract_test.dart`
Expected: FAIL 3 test.

- [ ] **Step 3: Sửa `create table` trong `20260830005`** — thay cả khối bằng:

```sql
create table if not exists sales.sales_order_return_status_projections (
  tenant_id uuid not null,
  sales_order_id uuid not null,
  return_status text not null,
  updated_at timestamptz not null default now(),
  constraint sales_order_return_status_projections_pkey
    primary key (tenant_id, sales_order_id),
  constraint sales_order_return_status_check
    check (return_status in ('none', 'partially_returned', 'fully_returned')),
  constraint sales_order_return_status_parent_fk
    foreign key (tenant_id, sales_order_id)
    references sales.sales_orders (tenant_id, id)
);
```

- [ ] **Step 4: Sửa upsert trong `confirm_return_exchange` (`20260904001`)**

```sql
-- trước
  insert into sales.sales_order_return_status_projections (
    tenant_id,
    sales_order_id,
    return_status,
    sold_quantity_micros,
    returned_quantity_micros,
    version,
    updated_at
  ) values (
    confirm_return_exchange.tenant_id,
    v_session.sales_order_id,
    v_return_status,
    v_sold_micros,
    v_returned_micros,
    1,
    now()
  )
  on conflict (tenant_id, sales_order_id) do update
  set
    return_status = excluded.return_status,
    sold_quantity_micros = excluded.sold_quantity_micros,
    returned_quantity_micros = excluded.returned_quantity_micros,
    version = sales.sales_order_return_status_projections.version + 1,
    updated_at = now();
-- sau
  insert into sales.sales_order_return_status_projections (
    tenant_id,
    sales_order_id,
    return_status,
    updated_at
  ) values (
    confirm_return_exchange.tenant_id,
    v_session.sales_order_id,
    v_return_status,
    now()
  )
  on conflict (tenant_id, sales_order_id) do update
  set
    return_status = excluded.return_status,
    updated_at = now();
```

- [ ] **Step 5: Sửa upsert trong `complete_return_exchange` (`20260830014`)** — giống Step 4, thay `confirm_return_exchange.tenant_id` bằng `complete_return_exchange.tenant_id`.

- [ ] **Step 6: Chạy test, xác nhận pass**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_07_return_status_projections_sql_contract_test.dart`
Expected: PASS.

- [ ] **Step 7: Tóm tắt + đề xuất commit, dừng chờ review**

Đề xuất: `refactor(sales): slim return status projection to status only`

---

### Task 2: Kiểm tra cân đối theo trạng thái (`006`)

- [ ] **Step 1: Thêm test (fail)** — thêm vào cuối `main()`:

```dart
  test('audit compares stored return status with per-line recomputation', () {
    final helperSql = _readMigration('20260830006_sales_shared_rpc_helpers.sql');
    final audit = _lastFunctionBlock(helperSql, 'sales.audit_sales_review_invariants');
    expect(audit, isNot(contains('return_projection_quantity_mismatch')));
    expect(audit, contains("'return_projection_status_mismatch'"));
    expect(audit, contains('return_line.original_sales_order_line_id = order_line.id'));
    expect(
      audit,
      contains('where projection.return_status is distinct from recomputed.return_status;'),
    );
    for (final column in removed) {
      expect(audit, isNot(contains('projection.$column')), reason: column);
    }
  });
```

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_07_return_status_projections_sql_contract_test.dart`
Expected: FAIL test mới.

- [ ] **Step 3: Sửa `audit_sales_review_invariants`** — thay nhánh cuối (từ `  union all` ngay trước `    'return_projection_quantity_mismatch',` đến hết `     or projection.returned_quantity_micros is distinct from sold.returned_qty;`) bằng:

```sql
  union all
  select
    'return_projection_status_mismatch',
    projection.tenant_id,
    projection.sales_order_id,
    projection.sales_order_id,
    'recomputable_from_line_snapshot',
    projection.return_status,
    recomputed.return_status,
    'per original line: completed returned quantity vs sold quantity; not Catalog'
  from sales.sales_order_return_status_projections projection
  join lateral (
    select case
      when count(*) = 0 then 'none'
      when bool_or(per_line.returned_qty > 0)
        and bool_and(per_line.returned_qty >= per_line.sold_qty) then 'fully_returned'
      when bool_or(per_line.returned_qty > 0) then 'partially_returned'
      else 'none'
    end as return_status
    from (
      select
        order_line.quantity_micros as sold_qty,
        coalesce((
          select sum(return_line.quantity_micros)
          from sales.return_exchange_lines return_line
          join sales.return_exchange_orders return_order
            on return_order.id = return_line.return_exchange_order_id
           and return_order.tenant_id = return_line.tenant_id
          where return_order.tenant_id = projection.tenant_id
            and return_order.sales_order_id = projection.sales_order_id
            and return_order.status = 'completed'
            and return_line.line_role = 'returned'
            and return_line.original_sales_order_line_id = order_line.id
        ), 0) as returned_qty
      from sales.sales_order_lines order_line
      where order_line.tenant_id = projection.tenant_id
        and order_line.sales_order_id = projection.sales_order_id
    ) per_line
  ) recomputed on true
  where projection.return_status is distinct from recomputed.return_status;
```

(Giữ nguyên dòng `$$;` và `revoke` ngay sau.)

- [ ] **Step 4: Chạy test, xác nhận pass**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_07_return_status_projections_sql_contract_test.dart test/domain/schema/sales_shared_rpc_helpers_sql_contract_test.dart`
Expected: PASS.

- [ ] **Step 5: Tóm tắt + đề xuất commit, dừng chờ review**

Đề xuất: `refactor(sales): audit return projection by status instead of mixed-unit quantities`

---

### Task 3: Sự kiện gửi số lượng gốc + `complete` tính theo từng dòng

- [ ] **Step 1: Thêm test (fail)** — thêm vào cuối `main()` (dùng lại map `upserts`):

```dart
  upserts.forEach((file, fn) {
    test('$fn computes status per line and emits base quantities', () {
      final body = _lastFunctionBlock(_readMigration(file), fn);
      expect(body, contains('with per_line as ('));
      expect(body, contains('l.base_quantity_micros as sold_base,'));
      expect(body, contains('sum(rl.base_quantity_micros) as base'));
      expect(body, contains("'soldBaseQuantityMicros', v_sold_base_micros,"));
      expect(body, contains("'returnedBaseQuantityMicros', v_returned_base_micros"));
      expect(body, isNot(contains('v_sold_micros')));
      expect(body, isNot(contains("'soldQuantityMicros'")));
    });
  });
```

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_07_return_status_projections_sql_contract_test.dart`
Expected: FAIL 2 test mới.

- [ ] **Step 3: Sửa `confirm_return_exchange` (`20260904001`)**

1. `declare`: `  v_sold_micros bigint;` → `  v_sold_base_micros bigint;`; `  v_returned_micros bigint;` → `  v_returned_base_micros bigint;`.
2. Thay câu tính trạng thái (từ `  with per_line as (` tới `  from per_line;`, giữ comment phía trên) bằng:

```sql
  with per_line as (
    select
      l.id,
      l.quantity_micros as sold_qty,
      l.base_quantity_micros as sold_base,
      coalesce(returned.qty, 0) as returned_qty,
      coalesce(returned.base, 0) as returned_base
    from sales.sales_order_lines l
    left join lateral (
      select sum(rl.quantity_micros) as qty, sum(rl.base_quantity_micros) as base
      from sales.return_exchange_lines rl
      join sales.return_exchange_orders r
        on r.id = rl.return_exchange_order_id and r.tenant_id = rl.tenant_id
      where r.tenant_id = confirm_return_exchange.tenant_id
        and r.sales_order_id = v_session.sales_order_id
        and r.status = 'completed'
        and rl.line_role = 'returned'
        and rl.original_sales_order_line_id = l.id
    ) returned on true
    where l.sales_order_id = v_session.sales_order_id
      and l.tenant_id = confirm_return_exchange.tenant_id
  )
  select
    coalesce(sum(sold_base), 0),
    coalesce(sum(returned_base), 0),
    case
      when count(*) = 0 then 'none'
      when bool_or(returned_qty > 0) and bool_and(returned_qty >= sold_qty)
        then 'fully_returned'
      when bool_or(returned_qty > 0) then 'partially_returned'
      else 'none'
    end
  into v_sold_base_micros, v_returned_base_micros, v_return_status
  from per_line;
```

3. Payload sự kiện:

```sql
-- trước
      'soldQuantityMicros', v_sold_micros,
      'returnedQuantityMicros', v_returned_micros
-- sau
      'soldBaseQuantityMicros', v_sold_base_micros,
      'returnedBaseQuantityMicros', v_returned_base_micros
```

- [ ] **Step 4: Sửa `complete_return_exchange` (`20260830014`)**

1. `declare`: đổi tên 2 biến như Step 3.1.
2. Thay đoạn tính tổng gộp (từ `  select coalesce(sum(l.quantity_micros), 0) into v_sold_micros` tới hết `  end;` của `v_return_status := case …`) bằng đúng CTE ở Step 3.2, thay mọi `confirm_return_exchange.tenant_id` bằng `complete_return_exchange.tenant_id`.
3. Payload sự kiện: đổi 2 key như Step 3.3.

- [ ] **Step 5: Chạy test, xác nhận pass**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_07_return_status_projections_sql_contract_test.dart`
Expected: PASS.

- [ ] **Step 6: Tóm tắt + đề xuất commit, dừng chờ review**

Đề xuất: `fix(sales): emit base-unit return quantities and compute completion status per line`

---

### Task 4: Kiểm chứng + tiến độ

- [ ] **Step 1: Grep + policy + toàn bộ test**
- `grep -nE "sold_quantity_micros|returned_quantity_micros|sales_order_return_status_projections\.version|'soldQuantityMicros'" supabase/migrations/2026083*.sql supabase/migrations/20260904001*.sql` → chỉ còn trong bản cũ `confirm_return_exchange` của `20260830014` (định nghĩa bị ghi đè, thân plpgsql không bị kiểm tra lúc tạo).
- `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart --strict` → OK.
- `cd modules/sales/infrastructure && dart test` → chỉ còn baseline fail.

- [ ] **Step 2: Tiến độ spec** — dòng bảng 7 README: `✅ Đã chốt · bỏ id, 2 cột số lượng, version; sự kiện gửi số lượng gốc · 📝 Plan … · 🧪 Đã sửa migration gốc, chờ reset`.

- [ ] **Step 3: Dừng — user reset + smoke test**

Sau `supabase db reset` (thực hiện sau plan 13 để `base_quantity_micros` của dòng trả đã đúng):
1. Đơn 2 dòng → đổi trả trả 1 phần dòng 1 → danh sách đơn hiện "Trả một phần"; lọc "có trả hàng" thấy đơn.
2. Trả hết cả 2 dòng → "Đã trả hết".
3. SQL Editor: `select * from sales.audit_sales_review_invariants();` → không có dòng `return_projection_status_mismatch`.
4. `select * from sales.sales_order_return_status_projections;` → 4 cột.
5. `select payload from sales.outbox_messages where event_type = 'return_exchange_completed.v1' order by created_at desc limit 1;` → có `soldBaseQuantityMicros`, `returnedBaseQuantityMicros` theo đơn vị gốc (vd bán 2 Hộp = 20 Viên → `soldBaseQuantityMicros` = 20 000 000).
