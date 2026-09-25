# Sales refactor — Bảng 12 `sales.return_exchange_orders` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bỏ 7 cột của `sales.return_exchange_orders` (`reason_code`, `idempotency_key`, `payload_hash`, `operation_type`, `causation_id`, `cancelled_at` + unique/CHECK kèm theo) cùng 3 đoạn code chết; thêm tham số `reason text default null` cho `start_return_exchange`/`update_return_exchange` để ghi cột `reason` — **sửa trực tiếp migration gốc**.

**Architecture:** Bảng ở `20260830005`. Mọi chỗ ghi/đọc cột bị bỏ nằm trong `20260830012` (`start`, `update`, `cancel` — file owner duy nhất của 3 hàm). `confirm`/`complete`/`settle` không đọc các cột này.

**Tech Stack:** PostgreSQL/Supabase plpgsql; Dart `package:test`.

**Spec:** [12-return-exchange-orders.md](../specs/sales-schema-refactor/12-return-exchange-orders.md) · Quy ước: [README §Quy ước implement](../specs/sales-schema-refactor/README.md#quy-ước-implement-sửa-trực-tiếp-migration-gốc)

## Global Constraints

- Tuân thủ **Quy ước implement**. Thứ tự: sau plan 11 (plan 1 đã đổi lời gọi helper trong `start`/`update`/`cancel`; plan 6 đã bỏ đoạn dự phòng snapshot trong `start`) — tìm theo nội dung.
- Giữ `complete_return_exchange` và mọi code Dart/ERP liên quan.
- Tham số `causation_id` của RPC giữ nguyên (không lưu). Không sửa Dart (app chưa gửi `reason`).
- Không `dart format` cả package; chỉ file test mới.
- **Không `git commit`** — cuối mỗi task tóm tắt + đề xuất commit rồi dừng.
- Trước khi sửa hàm: `node .gitnexus/run.cjs impact "<tên hàm>" --direction upstream --repo .` cho `start_return_exchange`, `update_return_exchange`, `cancel_return_exchange` (hàm SQL → `UNKNOWN`; đối chiếu khảo sát).

## Khảo sát

| Vị trí | Nội dung |
|---|---|
| `20260830005` `create table if not exists sales.return_exchange_orders` | 27 cột; `return_exchange_orders_idempotency_unique`, `return_exchange_orders_operation_check` |
| `20260830012` `start_return_exchange` | chữ ký kết thúc `reference_decision jsonb default '{}'::jsonb`; `declare v_existing …%rowtype;`; đoạn `select * into v_existing … idempotency_key … return v_result; end if;`; insert có `operation_type` (khối `case`), `reason_code` (`'SESSION'`), `idempotency_key`, `payload_hash`, `causation_id` |
| `20260830012` `update_return_exchange` | chữ ký như trên; 2 nhánh `if v_session.payload_hash … v_session.idempotency_key = update_return_exchange.idempotency_key`; update `set version …, operation_type = case … end, payload_hash = …, correlation_id = …, causation_id = …, updated_at = now()` |
| `20260830012` `cancel_return_exchange` | `cancelled_at = now(),` |
| `20260830012` cuối file | `revoke`/`grant` với chữ ký cũ của `start`/`update` |
| Nơi khác | Không migration nào khác đọc 6 cột bỏ; `sales_rpc_surface_parity_test` kiểm tra tham số Dart ⊆ SQL (thêm tham số vẫn pass); test plan 1 đếm 15 begin / 20 complete (sau plan 11) |

## File Structure

| File | Thay đổi |
|---|---|
| Modify `supabase/migrations/20260830005_sales_rebuild_schema.sql` | `create table` |
| Modify `supabase/migrations/20260830012_sales_return_exchange_session_rpcs.sql` | `start`, `update`, `cancel`, grant |
| Modify `modules/sales/infrastructure/test/domain/schema/sales_refactor_01_idempotency_records_sql_contract_test.dart` | 20 → 18 complete |
| Create `modules/sales/infrastructure/test/domain/schema/sales_refactor_12_return_exchange_orders_sql_contract_test.dart` | SQL contract test |
| Modify `docs/superpowers/specs/sales-schema-refactor/README.md` | Tiến độ + việc phát sinh |

---

### Task 1: Bảng + `start`/`update`/`cancel`

- [ ] **Step 1: Viết test (fail)**

```dart
import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Sales refactor bảng 12 `sales.return_exchange_orders`
/// (docs/superpowers/specs/sales-schema-refactor/12-return-exchange-orders.md).
void main() {
  final schemaSql = _readMigration('20260830005_sales_rebuild_schema.sql');
  final rxSql = _readMigration('20260830012_sales_return_exchange_session_rpcs.sql');
  const removed = [
    'reason_code',
    'idempotency_key',
    'payload_hash',
    'operation_type',
    'causation_id',
    'cancelled_at',
  ];

  test('return_exchange_orders drops dead columns and keeps reason', () {
    final start = schemaSql.indexOf(
      'create table if not exists sales.return_exchange_orders (',
    );
    final table = schemaSql.substring(start, schemaSql.indexOf('\n);', start));
    for (final column in removed) {
      expect(table, isNot(contains(column)), reason: column);
    }
    expect(table, contains('  reason text,'));
    expect(table, contains('correlation_id text,'));
    expect(table, contains('entry_source text,'));
  });

  test('start and update accept optional reason and persist it', () {
    for (final fn in ['sales.start_return_exchange', 'sales.update_return_exchange']) {
      final body = _lastFunctionBlock(rxSql, fn);
      expect(
        body,
        contains("  reference_decision jsonb default '{}'::jsonb,\n  reason text default null\n) returns jsonb"),
        reason: fn,
      );
    }
    final start = _lastFunctionBlock(rxSql, 'sales.start_return_exchange');
    expect(start, contains("nullif(btrim(start_return_exchange.reason), '')"));
    final update = _lastFunctionBlock(rxSql, 'sales.update_return_exchange');
    expect(update, contains("reason = nullif(btrim(update_return_exchange.reason), ''),"));
    expect(
      rxSql,
      contains(
        'grant execute on function sales.start_return_exchange(text, uuid, uuid, uuid, text, jsonb, text, text, text, text, integer, jsonb, text) to authenticated;',
      ),
    );
    expect(
      rxSql,
      contains(
        'grant execute on function sales.update_return_exchange(text, uuid, uuid, uuid, jsonb, text, text, text, text, integer, jsonb, text) to authenticated;',
      ),
    );
  });

  test('start/update/cancel no longer write or read dropped columns', () {
    final start = _lastFunctionBlock(rxSql, 'sales.start_return_exchange');
    final update = _lastFunctionBlock(rxSql, 'sales.update_return_exchange');
    final cancel = _lastFunctionBlock(rxSql, 'sales.cancel_return_exchange');
    expect(start, isNot(contains('v_existing')));
    expect(start, isNot(contains("'SESSION'")));
    expect(start, isNot(contains('operation_type')));
    expect(update, isNot(contains('operation_type')));
    expect(update, isNot(contains('v_session.payload_hash')));
    expect(update, isNot(contains('v_session.idempotency_key')));
    expect(update, isNot(contains('causation_id = ')));
    expect(cancel, isNot(contains('cancelled_at')));
    final insertStart = start.indexOf('insert into sales.return_exchange_orders (');
    final insert = start.substring(insertStart, start.indexOf(') values', insertStart));
    for (final column in removed) {
      expect(insert, isNot(contains(column)), reason: column);
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

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_12_return_exchange_orders_sql_contract_test.dart`
Expected: FAIL 3 test.

- [ ] **Step 3: Sửa `create table` trong `20260830005`** — thay cả khối bằng:

```sql
create table if not exists sales.return_exchange_orders (
  id uuid primary key,
  tenant_id uuid not null,
  sales_order_id uuid not null,
  status text not null,
  version bigint not null default 1,
  source_order_version bigint not null,
  created_by_user_id uuid not null,
  confirmed_by_user_id uuid,                                                   -- ADR-7: confirmation evidence on aggregate
  completed_by_user_id uuid,
  reason text,                                                                 -- optional session-level note; line reasons live on return_exchange_lines
  currency_code char(3) not null,
  entry_source text,
  source_settlement_version bigint,
  reference_number varchar(100),
  correlation_id text,
  confirmation_decision_snapshot jsonb,
  confirmed_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint return_exchange_orders_status_check
    check (status in ('draft', 'confirmed', 'processing', 'completed',
      'cancelled', 'blocked', 'failed')),
  constraint return_exchange_orders_parent_fk
    foreign key (tenant_id, sales_order_id)
    references sales.sales_orders (tenant_id, id),                             -- FC-01
  constraint return_exchange_orders_tenant_id_unique unique (tenant_id, id),
  constraint return_exchange_orders_tenant_id_id_order_unique
    unique (tenant_id, id, sales_order_id)                                     -- enables line source-order FK
);
```

- [ ] **Step 4: Sửa `start_return_exchange` (`20260830012`)**

1. Chữ ký — thêm tham số cuối:

```sql
-- trước
  expected_source_version integer default null,
  reference_decision jsonb default '{}'::jsonb
) returns jsonb
-- sau
  expected_source_version integer default null,
  reference_decision jsonb default '{}'::jsonb,
  reason text default null
) returns jsonb
```

2. `declare`: xoá dòng `  v_existing sales.return_exchange_orders%rowtype;`.
3. Xoá nguyên đoạn (ngay sau khối `if v_idem ->> 'decision' = 'in_progress' then … end if;`, kèm dòng trống theo sau):

```sql
  select * into v_existing
  from sales.return_exchange_orders
  where return_exchange_orders.tenant_id = start_return_exchange.tenant_id
    and return_exchange_orders.idempotency_key = start_return_exchange.idempotency_key
  for update;
  if found then
    if v_existing.payload_hash is distinct from start_return_exchange.payload_hash then
      raise exception using message = jsonb_build_object(
        'code', 'IDEMPOTENCY_CONFLICT',
        'message', 'Idempotency key was reused with a different payload.'
      )::text;
    end if;
    v_result := sales._get_return_exchange_context(
      start_return_exchange.tenant_id, start_return_exchange.actor_id, v_existing.id
    ) -> 'draft';
    perform sales._complete_sales_idempotency(
      tenant_id, 'start_return_exchange', trim(idempotency_key),
      'succeeded', v_result
    );
    return v_result;
  end if;
```

4. Thay cả câu `insert into sales.return_exchange_orders (…) values (…);` bằng:

```sql
  insert into sales.return_exchange_orders (
    id, tenant_id, sales_order_id, status, version, source_order_version,
    created_by_user_id, reason, currency_code,
    entry_source, source_settlement_version, reference_number, correlation_id
  ) values (
    v_session_id, start_return_exchange.tenant_id, v_order.id,
    'draft', 1, v_order.version, start_return_exchange.actor_id,
    nullif(btrim(start_return_exchange.reason), ''),
    v_order.currency_code,
    start_return_exchange.entry_source,
    coalesce(v_settlement.version, 1), v_reference_number,
    start_return_exchange.correlation_id
  );
```

- [ ] **Step 5: Sửa `update_return_exchange` (`20260830012`)**

1. Chữ ký — giống Step 4.1 (thêm `,\n  reason text default null` sau `reference_decision jsonb default '{}'::jsonb`).
2. Xoá 2 nhánh (ngay sau khối kiểm tra `expected_version … 'STALE_VERSION' … end if;`, kèm dòng trống theo sau):

```sql
  if v_session.payload_hash is not null
     and v_session.payload_hash is distinct from update_return_exchange.payload_hash
     and v_session.idempotency_key = update_return_exchange.idempotency_key then
    raise exception using message = jsonb_build_object(
      'code', 'IDEMPOTENCY_CONFLICT',
      'message', 'Idempotency key was reused with a different payload.'
    )::text;
  end if;
  if v_session.payload_hash is not distinct from update_return_exchange.payload_hash
     and v_session.idempotency_key = update_return_exchange.idempotency_key then
    v_result := sales._get_return_exchange_context(
      update_return_exchange.tenant_id, update_return_exchange.actor_id, v_session.id
    ) -> 'draft';
    perform sales._complete_sales_idempotency(
      tenant_id, 'update_return_exchange', trim(idempotency_key),
      'succeeded', v_result
    );
    return v_result;
  end if;
```

3. Thay câu update phiếu (từ `  update sales.return_exchange_orders` / `  set version = version + 1,` tới `  returning * into v_session;`) bằng:

```sql
  update sales.return_exchange_orders
  set version = version + 1,
      reason = nullif(btrim(update_return_exchange.reason), ''),
      correlation_id = update_return_exchange.correlation_id,
      updated_at = now()
  where id = v_session.id
    and tenant_id = update_return_exchange.tenant_id
  returning * into v_session;
```

- [ ] **Step 6: Sửa `cancel_return_exchange` (`20260830012`)** — xoá dòng `      cancelled_at = now(),`.

- [ ] **Step 7: Sửa `revoke`/`grant` cuối `20260830012`**

```sql
-- trước
revoke all on function sales.start_return_exchange(text, uuid, uuid, uuid, text, jsonb, text, text, text, text, integer, jsonb) from public, anon;
revoke all on function sales.update_return_exchange(text, uuid, uuid, uuid, jsonb, text, text, text, text, integer, jsonb) from public, anon;
…
grant execute on function sales.start_return_exchange(text, uuid, uuid, uuid, text, jsonb, text, text, text, text, integer, jsonb) to authenticated;
grant execute on function sales.update_return_exchange(text, uuid, uuid, uuid, jsonb, text, text, text, text, integer, jsonb) to authenticated;
-- sau
revoke all on function sales.start_return_exchange(text, uuid, uuid, uuid, text, jsonb, text, text, text, text, integer, jsonb, text) from public, anon;
revoke all on function sales.update_return_exchange(text, uuid, uuid, uuid, jsonb, text, text, text, text, integer, jsonb, text) from public, anon;
…
grant execute on function sales.start_return_exchange(text, uuid, uuid, uuid, text, jsonb, text, text, text, text, integer, jsonb, text) to authenticated;
grant execute on function sales.update_return_exchange(text, uuid, uuid, uuid, jsonb, text, text, text, text, integer, jsonb, text) to authenticated;
```

(Không cần `drop function if exists` chữ ký cũ: reset chạy từ DB rỗng và `start`/`update` chỉ được định nghĩa ở file này.)

- [ ] **Step 8: Kiểm tra xung đột tên `reason`** — tham số mới trùng tên cột `reason`. Chạy:

`awk '/^create or replace function sales.(start|update)_return_exchange\(/{p=1} p&&/\<reason\>/{print NR": "$0} p&&/^\$\$;/{p=0}' supabase/migrations/20260830012_sales_return_exchange_session_rpcs.sql`

Expected: mọi tham chiếu `reason` trong thân hàm đều viết đầy đủ (`start_return_exchange.reason`, `update_return_exchange.reason`) hoặc là tên cột bên trái `set reason =` / trong danh sách cột insert. Không có `reason` trần ở vế phải/điều kiện (nếu có, thêm tiền tố tên hàm).

- [ ] **Step 9: Sửa test plan 1** `sales_refactor_01_idempotency_records_sql_contract_test.dart`:

```dart
// trước
    expect(completeCalls, 20);
// sau
    expect(completeCalls, 18);
```

- [ ] **Step 10: Chạy test, xác nhận pass**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_12_return_exchange_orders_sql_contract_test.dart test/domain/schema/sales_refactor_01_idempotency_records_sql_contract_test.dart test/domain/schema/sales_rpc_surface_parity_test.dart test/domain/return_exchange_order/sales_return_exchange_group_i_session_sql_contract_test.dart`
Expected: PASS.

- [ ] **Step 11: Grep + policy + toàn bộ test**
- `grep -nE "operation_type|'SESSION'|return_exchange_orders_idempotency_unique|v_session\.payload_hash|v_session\.idempotency_key" supabase/migrations/*.sql` → không còn kết quả.
- `dart run tools/vet45_supabase_migrate/bin/seed_registry.dart --write && dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart --strict` → OK.
- `cd modules/sales/infrastructure && dart test` → chỉ còn baseline fail.

- [ ] **Step 12: Tiến độ spec** — dòng bảng 12 README: `✅ Đã chốt · bỏ 7 cột, reason ghi qua tham số mới · 📝 Plan … · 🧪 Đã sửa migration gốc, chờ reset`.

- [ ] **Step 13: Tóm tắt + đề xuất commit, dừng — user reset + smoke test**

Đề xuất commit: `refactor(sales): drop dead return/exchange order columns and accept optional reason`

Sau `supabase db reset`:
1. Mở đổi trả cho một đơn → thêm dòng trả + dòng đổi → lưu (update) → xác nhận → phiếu `completed`, màn kết quả hiển thị đúng.
2. Mở đổi trả khác → huỷ phiên → phiếu `cancelled`.
3. Gửi lại đúng lệnh `start` (cùng key) → trả kết quả cũ, không tạo phiếu thứ hai.
4. SQL Editor: `select sales.start_return_exchange(...)` với `reason => 'Khách đổi size'` (hoặc gọi thử qua RPC) → cột `reason` có giá trị; gọi không truyền `reason` → `null`.
