# Sales refactor — Bảng 11 `sales.sales_order_cancellations` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sửa FC-17 thành `unique (tenant_id, sales_order_id)`, bỏ 11 cột không dùng/trùng của `sales.sales_order_cancellations` cùng đoạn tra phiếu cũ theo `idempotency_key` — **sửa trực tiếp migration gốc**, không đổi contract RPC.

**Architecture:** Bảng ở `20260830005`. Ghi ở `confirm_sales_order_cancellation` (định nghĩa cuối `20260904001`). Đọc cột bị bỏ ở `get_sales_order_cancellation` (`011`) và `get_sales_order_timeline` (`010`). Bản cũ `confirm_sales_order_cancellation` trong `011` để nguyên.

**Tech Stack:** PostgreSQL/Supabase plpgsql; Dart `package:test`.

**Spec:** [11-sales-order-cancellations.md](../specs/sales-schema-refactor/11-sales-order-cancellations.md) · Quy ước: [README §Quy ước implement](../specs/sales-schema-refactor/README.md#quy-ước-implement-sửa-trực-tiếp-migration-gốc)

## Global Constraints

- Tuân thủ **Quy ước implement**. Thứ tự: sau plan 10 (plan 1 đã đổi lời gọi helper trong `confirm_sales_order_cancellation`) — tìm theo nội dung.
- Giữ CHECK `status` 8 giá trị và mọi chỗ lọc `status in (…)`.
- Key JSON không đổi (`cancelledByActorId`, `cancelledAt`, `status`, …).
- Không `dart format` cả package; chỉ file test mới.
- **Không `git commit`** — cuối task tóm tắt + đề xuất commit rồi dừng.
- Trước khi sửa hàm: `node .gitnexus/run.cjs impact "<tên hàm>" --direction upstream --repo .` cho `confirm_sales_order_cancellation`, `get_sales_order_cancellation`, `get_sales_order_timeline` (hàm SQL → `UNKNOWN`; đối chiếu khảo sát).

## Khảo sát

| Vị trí | Nội dung |
|---|---|
| `20260830005` `create table if not exists sales.sales_order_cancellations` | 22 cột; `sales_order_cancellations_idempotency_unique` |
| `20260830005` ngay sau `create table` | comment `-- Legacy 20260827005 …` + `alter table … drop column if exists reason_code;` + comment FC-17 + `create unique index … sales_order_cancellations_one_completed … where status = 'completed';` |
| `20260904001` `confirm_sales_order_cancellation` | `declare v_existing sales.sales_order_cancellations%rowtype;`; đoạn `select * into v_existing … idempotency_key = … ; if found then … return v_result; end if;`; insert có `version`, `confirmed_by_user_id`, `required_impacts_snapshot`, `idempotency_key` |
| `20260830011` `get_sales_order_cancellation` | `v_cancel_actor_id := coalesce(v_cancellation.confirmed_by_user_id, v_cancellation.requested_by_user_id);` |
| `20260830010` `get_sales_order_timeline` | `select coalesce(c.completed_by_user_id, c.confirmed_by_user_id, c.requested_by_user_id)::text` |
| Test | `sales_order_cancellation_group_h_sql_contract_test.dart:56-61` đòi `alter … drop column if exists reason_code;`; `sales_refactor_01_…_test.dart` đếm 15 begin / 21 complete (sau plan 10) |

## File Structure

| File | Thay đổi |
|---|---|
| Modify `supabase/migrations/20260830005_sales_rebuild_schema.sql` | `create table` + xoá alter/index cũ |
| Modify `supabase/migrations/20260904001_sales_normalize_outbox_and_commands.sql` | `confirm_sales_order_cancellation` |
| Modify `supabase/migrations/20260830011_sales_adjustment_cancellation_rpcs.sql` | `get_sales_order_cancellation` |
| Modify `supabase/migrations/20260830010_sales_inquiry_receipt_rpcs.sql` | timeline |
| Modify `modules/sales/infrastructure/test/domain/sales_order_cancellation/sales_order_cancellation_group_h_sql_contract_test.dart:56-61` | assertion |
| Modify `modules/sales/infrastructure/test/domain/schema/sales_refactor_01_idempotency_records_sql_contract_test.dart` | 21 → 20 complete |
| Create `modules/sales/infrastructure/test/domain/schema/sales_refactor_11_cancellations_sql_contract_test.dart` | SQL contract test |
| Modify `docs/superpowers/specs/sales-schema-refactor/README.md` | Tiến độ |

---

### Task 1: Bảng + ghi/đọc phiếu huỷ

- [ ] **Step 1: Viết test (fail)**

```dart
import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Sales refactor bảng 11 `sales.sales_order_cancellations`
/// (docs/superpowers/specs/sales-schema-refactor/11-sales-order-cancellations.md).
void main() {
  final schemaSql = _readMigration('20260830005_sales_rebuild_schema.sql');
  // `version` is checked separately: it is a substring of kept `source_order_version`.
  const removed = [
    'confirmed_by_user_id',
    'completed_by_user_id',
    'required_impacts_snapshot',
    'blocker_codes',
    'idempotency_key',
    'requested_at',
    'completed_at',
    'blocked_at',
    'failed_at',
    'updated_at',
  ];

  test('cancellations table keeps 10 columns and one cancellation per order', () {
    final start = schemaSql.indexOf(
      'create table if not exists sales.sales_order_cancellations (',
    );
    final table = schemaSql.substring(start, schemaSql.indexOf('\n);', start));
    for (final column in removed) {
      expect(table, isNot(contains(column)), reason: column);
    }
    expect(table, isNot(contains('  version bigint')));
    expect(table, contains('unique (tenant_id, sales_order_id)'));
    expect(table, contains("'completed', 'blocked', 'failed', 'cancelled'"));
    expect(schemaSql, isNot(contains('sales_order_cancellations_one_completed')));
    expect(schemaSql, isNot(contains('alter table sales.sales_order_cancellations')));
  });

  test('confirm inserts kept columns and has no key-based lookup', () {
    final confirm = _lastFunctionBlock(
      _readMigration('20260904001_sales_normalize_outbox_and_commands.sql'),
      'sales.confirm_sales_order_cancellation',
    );
    expect(confirm, isNot(contains('v_existing')));
    final start = confirm.indexOf('insert into sales.sales_order_cancellations (');
    final insert = confirm.substring(start, confirm.indexOf('returning * into v_inserted;', start));
    for (final column in removed) {
      expect(insert, isNot(contains(column)), reason: column);
    }
    expect(insert, isNot(contains('status, version,')));
  });

  test('readers use requested_by_user_id as the cancelling actor', () {
    final get = _lastFunctionBlock(
      _readMigration('20260830011_sales_adjustment_cancellation_rpcs.sql'),
      'sales.get_sales_order_cancellation',
    );
    expect(get, contains('v_cancel_actor_id := v_cancellation.requested_by_user_id;'));
    final timeline = _lastFunctionBlock(
      _readMigration('20260830010_sales_inquiry_receipt_rpcs.sql'),
      'sales.get_sales_order_timeline',
    );
    expect(timeline, contains('select c.requested_by_user_id::text'));
    expect(timeline, isNot(contains('c.completed_by_user_id')));
    expect(timeline, isNot(contains('c.confirmed_by_user_id')));
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

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_11_cancellations_sql_contract_test.dart`
Expected: FAIL 3 test.

- [ ] **Step 3: Sửa `20260830005`** — thay cả khối từ `create table if not exists sales.sales_order_cancellations (` tới hết `  where status = 'completed';` (gồm comment `-- Legacy 20260827005 …`, câu `alter … drop column if exists reason_code;`, comment FC-17 và partial index) bằng:

```sql
create table if not exists sales.sales_order_cancellations (
  id uuid primary key,
  tenant_id uuid not null,
  sales_order_id uuid not null,
  status text not null,
  source_order_version bigint not null,
  requested_by_user_id uuid not null,
  reason text,
  precheck_snapshot jsonb not null,
  confirmed_at timestamptz,
  created_at timestamptz not null default now(),
  constraint sales_order_cancellations_order_unique
    unique (tenant_id, sales_order_id),                                        -- FC-17: ≤1 cancellation per order
  constraint sales_order_cancellations_status_check
    check (status in ('requested', 'validating', 'confirmed', 'processing',
      'completed', 'blocked', 'failed', 'cancelled')),
  constraint sales_order_cancellations_parent_fk
    foreign key (tenant_id, sales_order_id)
    references sales.sales_orders (tenant_id, id)                               -- FC-01
);
```

- [ ] **Step 4: Sửa `confirm_sales_order_cancellation` (`20260904001`)**

1. `declare`: xoá dòng `  v_existing sales.sales_order_cancellations%rowtype;`.
2. Xoá nguyên đoạn (ngay sau khối `if v_idem ->> 'decision' = 'in_progress' then … end if;`, kèm dòng trống theo sau):

```sql
  select * into v_existing
  from sales.sales_order_cancellations
  where sales_order_cancellations.tenant_id = confirm_sales_order_cancellation.tenant_id
    and sales_order_cancellations.idempotency_key = confirm_sales_order_cancellation.idempotency_key;
  if found then
    if (v_existing.precheck_snapshot ->> 'payloadHash') is distinct from confirm_sales_order_cancellation.payload_hash then
      raise exception using message = jsonb_build_object(
        'code', 'IDEMPOTENCY_CONFLICT',
        'message', 'Idempotency key was reused with a different payload.'
      )::text;
    end if;
    v_result := jsonb_build_object(
      'cancellationId', v_existing.id,
      'salesOrderId', v_existing.sales_order_id,
      'salesOrderVersion', coalesce(
        (v_existing.precheck_snapshot ->> 'resultingOrderVersion')::bigint,
        v_existing.source_order_version + 1
      ),
      'status', v_existing.status
    );
    perform sales._complete_sales_idempotency(
      tenant_id, 'confirm_sales_order_cancellation', trim(idempotency_key),
      'succeeded', v_result
    );
    return v_result;
  end if;
```

3. Insert:

```sql
-- trước
  insert into sales.sales_order_cancellations (
    id, tenant_id, sales_order_id, status, version, source_order_version,
    requested_by_user_id, confirmed_by_user_id, reason,
    precheck_snapshot, required_impacts_snapshot, idempotency_key,
    confirmed_at
  ) values (
    v_id,
    confirm_sales_order_cancellation.tenant_id,
    confirm_sales_order_cancellation.sales_order_id,
    'confirmed',
    1,
    v_order.version,
    confirm_sales_order_cancellation.actor_id,
    confirm_sales_order_cancellation.actor_id,
    nullif(v_reason_text, ''),
    v_decision_snapshot,
    v_decision_snapshot -> 'impacts',
    confirm_sales_order_cancellation.idempotency_key,
    now()
  )
  returning * into v_inserted;
-- sau
  insert into sales.sales_order_cancellations (
    id, tenant_id, sales_order_id, status, source_order_version,
    requested_by_user_id, reason, precheck_snapshot, confirmed_at
  ) values (
    v_id,
    confirm_sales_order_cancellation.tenant_id,
    confirm_sales_order_cancellation.sales_order_id,
    'confirmed',
    v_order.version,
    confirm_sales_order_cancellation.actor_id,
    nullif(v_reason_text, ''),
    v_decision_snapshot,
    now()
  )
  returning * into v_inserted;
```

- [ ] **Step 5: Sửa `get_sales_order_cancellation` (`20260830011`)**

```sql
-- trước
  v_cancel_actor_id := coalesce(
    v_cancellation.confirmed_by_user_id,
    v_cancellation.requested_by_user_id
  );
-- sau
  v_cancel_actor_id := v_cancellation.requested_by_user_id;
```

- [ ] **Step 6: Sửa `get_sales_order_timeline` (`20260830010`)**

```sql
-- trước
                  select coalesce(
                    c.completed_by_user_id,
                    c.confirmed_by_user_id,
                    c.requested_by_user_id
                  )::text
-- sau
                  select c.requested_by_user_id::text
```

- [ ] **Step 7: Sửa test cũ** `sales_order_cancellation_group_h_sql_contract_test.dart`:

```dart
// trước
    expect(
      schema,
      contains(
        'alter table sales.sales_order_cancellations\n'
        '  drop column if exists reason_code;',
      ),
    );
// sau
    expect(schema, isNot(contains('alter table sales.sales_order_cancellations')));
```

- [ ] **Step 8: Sửa test plan 1** `sales_refactor_01_idempotency_records_sql_contract_test.dart`:

```dart
// trước
    expect(completeCalls, 21);
// sau
    expect(completeCalls, 20);
```

- [ ] **Step 9: Chạy test, xác nhận pass**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_11_cancellations_sql_contract_test.dart test/domain/schema/sales_refactor_01_idempotency_records_sql_contract_test.dart test/domain/sales_order_cancellation/sales_order_cancellation_group_h_sql_contract_test.dart`
Expected: PASS.

- [ ] **Step 10: Grep + policy + toàn bộ test**
- `grep -nE "one_completed|required_impacts_snapshot|blocker_codes|c\.completed_by_user_id|v_cancellation\.confirmed_by_user_id" supabase/migrations/*.sql` → chỉ còn trong bản cũ `confirm_sales_order_cancellation` của `011` (nếu có).
- `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart --strict` → OK.
- `cd modules/sales/infrastructure && dart test` → chỉ còn baseline fail.

- [ ] **Step 11: Tiến độ spec** — dòng bảng 11 README: `✅ Đã chốt · FC-17 = unique theo đơn, bỏ 11 cột · 📝 Plan … · 🧪 Đã sửa migration gốc, chờ reset`.

- [ ] **Step 12: Tóm tắt + đề xuất commit, dừng — user reset + smoke test**

Đề xuất commit: `refactor(sales): enforce one cancellation per order and drop unused cancellation columns`

Sau `supabase db reset`:
1. Huỷ 1 đơn có lý do → chi tiết phiếu huỷ hiện đúng lý do, thời điểm, người huỷ; timeline hiện người huỷ.
2. Gửi lại đúng lệnh huỷ (cùng key) → trả kết quả cũ, không lỗi.
3. Thử huỷ lại đơn đã huỷ bằng key khác → bị chặn.
4. Mở đổi trả cho đơn đã huỷ → bị chặn.
5. SQL Editor: `select * from sales.sales_order_cancellations;` → 10 cột.
