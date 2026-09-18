# IAM refactor — Bảng 12: gộp 8 bảng chống lặp thành `iam.idempotency_records` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thay 8 bảng idempotency bằng `iam.idempotency_records` + 2 helper, giữ nguyên hành vi chống lặp của 10 lệnh; xoá phần theo dõi bước onboarding đã chết (RPC get/retry + Dart). **Sửa trực tiếp migration gốc.**

**Architecture:** Task 1 thêm bảng + helper vào `20260811005` (thay chỗ tạo `platform_user_lifecycle_operations`) và xoá câu tạo 7 bảng còn lại + grant/alter liên quan. Task 2–3 sửa định nghĩa cuối của 10 hàm; xoá 2 RPC get/retry trong `20260811006`. Task 4 xoá phần Dart get/retry + codegen. Task 5 kiểm chứng. Không đổi chữ ký các RPC còn lại.

**Tech Stack:** PostgreSQL/Supabase plpgsql; Dart `package:test`; `build_runner`.

**Spec:** [12-idempotency-records.md](../specs/iam-schema-refactor/12-idempotency-records.md) · Quy ước: [README §Quy ước implement](../specs/iam-schema-refactor/README.md#quy-ước-implement-sửa-trực-tiếp-migration-gốc)

## Global Constraints

- Tuân thủ **Quy ước implement**. Plan **cuối** chuỗi (sau 1, 2, 3, 4, 6, 8); văn bản "trước" đã gồm thay đổi các plan trước.
- Ánh xạ cố định:

  | Lệnh | `operation` | `scope_id` | hash | result |
  |---|---|---|---|---|
  | onboarding | `'tenant.onboard'` | `'platform'` | `null` | kết quả |
  | tạo lời mời | `'tenant.invitation.create'` | `p_tenant_id::text` | `v_payload_hash` | kết quả |
  | gửi lại | `'tenant.invitation.resend'` | `p_invitation_id::text` | `v_payload_hash` | kết quả |
  | thu hồi | `'tenant.invitation.revoke'` | `p_invitation_id::text` | `v_payload_hash` | kết quả |
  | chấp nhận | `'tenant.invitation.accept'` | `v_hash` | `v_payload_hash` | kết quả |
  | từ chối | `'tenant.invitation.decline'` | `v_hash` | `v_payload_hash` | kết quả |
  | kích hoạt | `'tenant.activate'` | `p_tenant_id::text` | `v_payload_hash` | kết quả |
  | chuyển chủ | `'tenant.ownership.transfer'` | `'platform'` | `v_fp` | `null` |
  | tạm ngừng user | `'platform_user.suspend'` | `'platform'` | `v_fp` | `null` |
  | mời lại chủ | `'tenant.owner.reinvite'` | `'platform'` | `null` | kết quả |

- Hành vi giữ nguyên: gặp bản ghi → trả `result` cũ (hoặc `return;`); khác hash (cả hai không null) → `IDEMPOTENCY_CONFLICT`.
- Không promote, **không `git commit`** — cuối task tóm tắt + đề xuất commit rồi dừng.
- Trước khi sửa hàm/class: `node .gitnexus/run.cjs impact "<tên>" --direction upstream --repo .`.
- Không `dart format` cả package; chỉ chạy codegen IAM.

## Khảo sát

**Câu lệnh tạo / chạy trực tiếp phải xoá:**

| File | Câu lệnh |
|---|---|
| `20260811005_iam_platform_user_lifecycle.sql` | `create table iam.platform_user_lifecycle_operations` → **thay bằng** bảng mới + helper |
| `20260811006_iam_create_tenant_onboarding.sql` | `create table iam.onboarding_operations`; `revoke all on table iam.onboarding_operations …`; `alter table iam.onboarding_operations add column …` (6 cột); hàm `get_tenant_onboarding_operation`, `retry_tenant_onboarding_operation`; header `-- Touches:` |
| `20260811012_iam_platform_transfer_ownership.sql` | `create table iam.ownership_transfer_operations`; `revoke …`; `alter … add column payload_fingerprint` |
| `20260811016_iam_tenant_readiness_activate.sql` | `create table iam.tenant_activation_operations` |
| `20260811017_iam_tenant_invitation_create.sql` | `create table iam.tenant_invitation_operations` |
| `20260811018_iam_tenant_invitation_resend_revoke.sql` | `create table iam.tenant_invitation_mutate_operations` |
| `20260811020_iam_tenant_invitation_acceptance.sql` | `create table iam.tenant_invitation_token_operations` |
| `20260826001_iam_fix_utc_now_offset.sql` | 3 câu `alter table iam.tenant_invitation_*_operations alter column created_at set default now();`; header `-- Touches:` |
| `20260911006_iam_reinvite_provisioning_owner.sql` | `create table iam.provisioning_owner_reinvite_operations`; `revoke …` |

**Định nghĩa cuối cần sửa:**

| Hàm | File owner |
|---|---|
| `create_tenant_onboarding` | `20260916004_iam_patch_onboarding_default_store_scope.sql` |
| `create_tenant_invitation`, `revoke_tenant_invitation`, `decline_invitation` | `20260916005_iam_patch_invitation_membership_store_scope.sql` |
| `resend_tenant_invitation` | `20260826002_iam_tenant_audit_history_v2_payloads.sql` |
| `accept_invitation` | `20260916006_iam_patch_accept_invitation_default_store_scope.sql` |
| `activate_tenant` | `20260916007_iam_patch_activate_tenant_default_store_scope.sql` |
| `transfer_platform_tenant_ownership` | `20260811012_iam_platform_transfer_ownership.sql` |
| `suspend_platform_user` | `20260820002_iam_platform_user_suspend_state_changed_fix.sql` |
| `reinvite_provisioning_owner` | `20260911006_iam_reinvite_provisioning_owner.sql` |

Bản plpgsql cũ ở file khác (vd `create_tenant_onboarding` trong `20260811006`) còn nhắc bảng cũ → để nguyên.

## File Structure

| File | Thay đổi |
|---|---|
| Modify migration theo Khảo sát | Sửa tại chỗ |
| Create `modules/iam/infrastructure/test/iam_refactor_12_idempotency_records_sql_contract_test.dart` | SQL contract test |
| Delete `modules/iam/application/lib/src/platform/queries/get_tenant_onboarding_operation/` (2 file), `…/commands/retry_tenant_onboarding_operation/` (3 file), `…/shared/tenant_onboarding_operation_dto.dart`, `…/shared/tenant_onboarding_operation_status.dart` | Dart chết |
| Modify `application.dart`, `i_platform_admin_gateway.dart`, `supabase_platform_admin_gateway.dart`, `fake_iam_module.dart`, `fake_iam_scenario.dart`, `stub_platform_admin_gateway.dart`, `scn_e01_u03_fr01_01_create_tenant_onboarding_test.dart`, `iam_contract_fake_scenario_matrix_test.dart` | Bỏ tham chiếu |
| Regenerate `modules/iam/infrastructure/lib/src/configuration/processing/generated/*.g.dart` | Codegen |
| Modify `docs/superpowers/specs/iam-schema-refactor/README.md` | Tiến độ |

Chạy test: `cd modules/iam/infrastructure && dart test test/iam_refactor_12_idempotency_records_sql_contract_test.dart`

---

### Task 1: Bảng mới + xoá câu tạo bảng cũ

**Files:**
- Create: test file
- Modify: 9 migration ở bảng Khảo sát (phần DDL)

**Interfaces:**
- Produces: `iam.idempotency_records`; `iam._idempotency_find(text, text, text, text) returns iam.idempotency_records`; `iam._idempotency_store(text, text, text, text, jsonb) returns void`. Test helper `_readMigration`, `_lastFunctionBlock`, `_expectUsesIdempotencyRecords`, `_legacyTables`.

- [ ] **Step 1: Viết test (fail)**

```dart
import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — IAM refactor bảng 12: unified idempotency store
/// (docs/superpowers/specs/iam-schema-refactor/12-idempotency-records.md).
void main() {
  group('idempotency_records DDL', () {
    final lifecycle = _readMigration('20260811005_iam_platform_user_lifecycle.sql');

    test('table and helpers live in 20260811005', () {
      expect(lifecycle, contains('create table if not exists iam.idempotency_records ('));
      expect(lifecycle, contains('primary key (operation, scope_id, idempotency_key)'));
      final find = _lastFunctionBlock(lifecycle, 'iam._idempotency_find');
      expect(find, contains('v_row.payload_hash is distinct from p_payload_hash'));
      expect(find, contains("raise exception 'IDEMPOTENCY_CONFLICT';"));
      expect(_lastFunctionBlock(lifecycle, 'iam._idempotency_store'), contains('insert into iam.idempotency_records'));
      expect(lifecycle, contains('revoke all on function iam._idempotency_find(text, text, text, text) from public, anon, authenticated;'));
      expect(lifecycle, contains('revoke all on function iam._idempotency_store(text, text, text, text, jsonb) from public, anon, authenticated;'));
    });

    test('no migration creates or alters legacy idempotency tables', () {
      final dir = Directory('${_findRepoRoot().path}/supabase/migrations');
      for (final file in dir.listSync().whereType<File>().where((f) => f.path.endsWith('.sql'))) {
        final sql = file.readAsStringSync();
        for (final table in _legacyTables) {
          expect(sql, isNot(contains('create table if not exists iam.$table')), reason: '${file.path} $table');
          expect(sql, isNot(contains('alter table iam.$table')), reason: '${file.path} $table');
          expect(sql, isNot(contains('revoke all on table iam.$table')), reason: '${file.path} $table');
        }
      }
    });

    test('dead onboarding operation rpcs removed', () {
      final onboarding = _readMigration('20260811006_iam_create_tenant_onboarding.sql');
      expect(onboarding, isNot(contains('get_tenant_onboarding_operation')));
      expect(onboarding, isNot(contains('retry_tenant_onboarding_operation')));
    });
  });
}

const _legacyTables = [
  'onboarding_operations',
  'tenant_invitation_operations',
  'tenant_invitation_mutate_operations',
  'tenant_invitation_token_operations',
  'tenant_activation_operations',
  'ownership_transfer_operations',
  'platform_user_lifecycle_operations',
  'provisioning_owner_reinvite_operations',
];

void _expectUsesIdempotencyRecords(Map<String, (String, String)> byFunction) {
  for (final entry in byFunction.entries) {
    final (file, operation) = entry.value;
    final body = _lastFunctionBlock(_readMigration(file), entry.key);
    for (final table in _legacyTables) {
      expect(body, isNot(contains('iam.$table')), reason: '${entry.key} → $table');
    }
    expect(body, contains("iam._idempotency_find('$operation',"), reason: entry.key);
    expect(body, contains("iam._idempotency_store('$operation',"), reason: entry.key);
  }
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

- [ ] **Step 2: Chạy test, xác nhận fail.**

- [ ] **Step 3: `20260811005_iam_platform_user_lifecycle.sql`**

Thay:
```sql
create table if not exists iam.platform_user_lifecycle_operations (
  idempotency_key text primary key,
  user_id uuid not null,
  action text not null,
  payload_fingerprint text not null,
  created_at timestamptz not null default now()
);
```
bằng:
```sql
-- Unified idempotency store for IAM commands (replaces per-command *_operations tables).
create table if not exists iam.idempotency_records (
  operation        text        not null,
  scope_id         text        not null,
  idempotency_key  text        not null,
  payload_hash     text,
  result           jsonb,
  created_at       timestamptz not null default now(),
  primary key (operation, scope_id, idempotency_key)
);

alter table iam.idempotency_records enable row level security;
revoke all on table iam.idempotency_records from public, anon, authenticated;

create or replace function iam._idempotency_find(
  p_operation text,
  p_scope_id text,
  p_key text,
  p_payload_hash text
)
returns iam.idempotency_records
language plpgsql
stable
security definer
set search_path = iam, pg_temp
as $$
declare
  v_row iam.idempotency_records;
begin
  select * into v_row
  from iam.idempotency_records r
  where r.operation = p_operation
    and r.scope_id = p_scope_id
    and r.idempotency_key = p_key;

  if found
     and p_payload_hash is not null
     and v_row.payload_hash is not null
     and v_row.payload_hash is distinct from p_payload_hash then
    raise exception 'IDEMPOTENCY_CONFLICT';
  end if;

  return v_row;
end;
$$;

create or replace function iam._idempotency_store(
  p_operation text,
  p_scope_id text,
  p_key text,
  p_payload_hash text,
  p_result jsonb
)
returns void
language sql
security definer
set search_path = iam, pg_temp
as $$
  insert into iam.idempotency_records (operation, scope_id, idempotency_key, payload_hash, result)
  values (p_operation, p_scope_id, p_key, p_payload_hash, p_result);
$$;

revoke all on function iam._idempotency_find(text, text, text, text) from public, anon, authenticated;
revoke all on function iam._idempotency_store(text, text, text, text, jsonb) from public, anon, authenticated;
```
Header `-- Touches:` thêm `, iam._idempotency_find, iam._idempotency_store`.

- [ ] **Step 4: `20260811006_iam_create_tenant_onboarding.sql`**
1. Xoá `create table if not exists iam.onboarding_operations ( … );`
2. Xoá `revoke all on table iam.onboarding_operations from public, anon, authenticated;`
3. Xoá khối `alter table iam.onboarding_operations add column if not exists operation_id … owner_user_id uuid;` (cùng comment `-- Task-10 contract patch: durable onboarding operation get/retry` ngay trên nếu có).
4. Xoá hàm `create or replace function iam.get_tenant_onboarding_operation(` … `$$;` và `create or replace function iam.retry_tenant_onboarding_operation(` … `$$;` cùng mọi `revoke`/`grant` của chúng trong file.
5. Header: bỏ `iam.get_tenant_onboarding_operation, iam.retry_tenant_onboarding_operation, ` khỏi `-- Touches:`.

- [ ] **Step 5: `20260811012_iam_platform_transfer_ownership.sql`** — xoá:
```sql
create table if not exists iam.ownership_transfer_operations (
  idempotency_key text primary key,
  tenant_id uuid not null,
  new_owner_user_id uuid not null,
  created_at timestamptz not null default now()
);

revoke all on table iam.ownership_transfer_operations from public, anon, authenticated;

alter table iam.ownership_transfer_operations
  add column if not exists payload_fingerprint text;
```

- [ ] **Step 6: Xoá câu `create table` đơn lẻ**
- `20260811016_…`: `create table if not exists iam.tenant_activation_operations ( … );`
- `20260811017_…`: `create table if not exists iam.tenant_invitation_operations ( … );` (cùng comment `-- ── Idempotency store ──` ngay trên)
- `20260811018_…`: `create table if not exists iam.tenant_invitation_mutate_operations ( … );`
- `20260811020_…`: `create table if not exists iam.tenant_invitation_token_operations ( … );` (cùng comment ngay trên)

- [ ] **Step 7: `20260826001_iam_fix_utc_now_offset.sql`**
1. Xoá 3 dòng `alter table iam.tenant_invitation_operations alter column created_at set default now();`, `…mutate_operations…`, `…token_operations…`.
2. Header: bỏ `iam.tenant_invitation_operations, iam.tenant_invitation_mutate_operations, iam.tenant_invitation_token_operations, ` khỏi `-- Touches:`.

- [ ] **Step 8: `20260911006_iam_reinvite_provisioning_owner.sql`** — xoá:
```sql
create table if not exists iam.provisioning_owner_reinvite_operations (
  idempotency_key text primary key,
  tenant_id uuid not null,
  result jsonb not null,
  created_at timestamptz not null default now()
);

revoke all on table iam.provisioning_owner_reinvite_operations from public, anon, authenticated;
```

- [ ] **Step 9: Chạy test, xác nhận pass** (3 test của group DDL).

- [ ] **Step 10: Dừng — tóm tắt.** Đề xuất commit: `refactor(iam): unified idempotency_records replaces per-command tables`.

---

### Task 2: 6 lệnh onboarding / lời mời (file owner)

**Files:**
- Modify: test file + `20260916004_…`, `20260916005_…`, `20260826002_…`, `20260916006_…`

- [ ] **Step 1: Thêm test (fail)**

```dart
  group('onboarding/invitation idempotency', () {
    test('uses idempotency_records', () => _expectUsesIdempotencyRecords(const {
          'iam.create_tenant_onboarding': ('20260916004_iam_patch_onboarding_default_store_scope.sql', 'tenant.onboard'),
          'iam.create_tenant_invitation': ('20260916005_iam_patch_invitation_membership_store_scope.sql', 'tenant.invitation.create'),
          'iam.resend_tenant_invitation': ('20260826002_iam_tenant_audit_history_v2_payloads.sql', 'tenant.invitation.resend'),
          'iam.revoke_tenant_invitation': ('20260916005_iam_patch_invitation_membership_store_scope.sql', 'tenant.invitation.revoke'),
          'iam.accept_invitation': ('20260916006_iam_patch_accept_invitation_default_store_scope.sql', 'tenant.invitation.accept'),
          'iam.decline_invitation': ('20260916005_iam_patch_invitation_membership_store_scope.sql', 'tenant.invitation.decline'),
        }));
  });
```

- [ ] **Step 2: Chạy test, xác nhận fail.**

- [ ] **Step 3: `create_tenant_onboarding`** (`20260916004_…`)
1. `declare`: `  v_existing jsonb;` → `  v_existing iam.idempotency_records;`
2. Thay:
```sql
  select result into v_existing
  from iam.onboarding_operations
  where idempotency_key = p_idempotency_key;

  if v_existing is not null then
    return v_existing;
  end if;
```
bằng:
```sql
  v_existing := iam._idempotency_find('tenant.onboard', 'platform', p_idempotency_key, null);
  if v_existing.idempotency_key is not null then
    return v_existing.result;
  end if;
```
3. `  insert into iam.onboarding_operations (idempotency_key, correlation_id, result)\n  values (p_idempotency_key, v_correlation, v_result);` → `  perform iam._idempotency_store('tenant.onboard', 'platform', p_idempotency_key, null, v_result);`

- [ ] **Step 4: `create_tenant_invitation`** (`20260916005_…`)
1. `declare`: `  v_existing_op iam.tenant_invitation_operations;` → `  v_existing_op iam.idempotency_records;`
2. Thay:
```sql
  select * into v_existing_op
  from iam.tenant_invitation_operations o
  where o.tenant_id = p_tenant_id
    and o.idempotency_key = p_idempotency_key;

  if found then
    if v_existing_op.payload_hash <> v_payload_hash then
      raise exception 'IDEMPOTENCY_CONFLICT';
    end if;
    return v_existing_op.result;
  end if;
```
bằng:
```sql
  v_existing_op := iam._idempotency_find('tenant.invitation.create', p_tenant_id::text, p_idempotency_key, v_payload_hash);
  if v_existing_op.idempotency_key is not null then
    return v_existing_op.result;
  end if;
```
3. Thay:
```sql
  insert into iam.tenant_invitation_operations (
    tenant_id,
    idempotency_key,
    payload_hash,
    result
  )
  values (
    p_tenant_id,
    p_idempotency_key,
    v_payload_hash,
    v_result
  );
```
bằng `  perform iam._idempotency_store('tenant.invitation.create', p_tenant_id::text, p_idempotency_key, v_payload_hash, v_result);`

- [ ] **Step 5: `resend_tenant_invitation`** (`20260826002_…`) và **`revoke_tenant_invitation`** (`20260916005_…`) — với `<op>` = `resend` / `revoke`:
1. `declare`: `  v_existing iam.tenant_invitation_mutate_operations;` → `  v_existing iam.idempotency_records;`
2. Thay:
```sql
  select * into v_existing
  from iam.tenant_invitation_mutate_operations o
  where o.tenant_id = p_tenant_id
    and o.invitation_id = p_invitation_id
    and o.operation = '<op>'
    and o.idempotency_key = p_idempotency_key;

  if found then
    if v_existing.payload_hash <> v_payload_hash then
      raise exception 'IDEMPOTENCY_CONFLICT';
    end if;
    return v_existing.result;
  end if;
```
bằng:
```sql
  v_existing := iam._idempotency_find('tenant.invitation.<op>', p_invitation_id::text, p_idempotency_key, v_payload_hash);
  if v_existing.idempotency_key is not null then
    return v_existing.result;
  end if;
```
3. Thay:
```sql
  insert into iam.tenant_invitation_mutate_operations (
    tenant_id, invitation_id, operation, idempotency_key, payload_hash, result
  ) values (
    p_tenant_id, p_invitation_id, '<op>', p_idempotency_key, v_payload_hash, v_result
  );
```
bằng `  perform iam._idempotency_store('tenant.invitation.<op>', p_invitation_id::text, p_idempotency_key, v_payload_hash, v_result);`

- [ ] **Step 6: `accept_invitation`** (`20260916006_…`) và **`decline_invitation`** (`20260916005_…`) — với `<op>` = `accept` / `decline`:
1. `declare`: `  v_existing iam.tenant_invitation_token_operations;` → `  v_existing iam.idempotency_records;`
2. Thay:
```sql
  select * into v_existing
  from iam.tenant_invitation_token_operations o
  where o.token_hash = v_hash
    and o.operation = '<op>'
    and o.idempotency_key = p_idempotency_key;

  if found then
    if v_existing.payload_hash <> v_payload_hash then
      raise exception 'IDEMPOTENCY_CONFLICT';
    end if;
    return v_existing.result;
  end if;
```
bằng:
```sql
  v_existing := iam._idempotency_find('tenant.invitation.<op>', v_hash, p_idempotency_key, v_payload_hash);
  if v_existing.idempotency_key is not null then
    return v_existing.result;
  end if;
```
3. Thay **mọi** khối (accept **2**, decline 1):
```sql
      insert into iam.tenant_invitation_token_operations (
        token_hash, operation, idempotency_key, payload_hash, result
      ) values (
        v_hash, '<op>', p_idempotency_key, v_payload_hash, v_result
      );
```
bằng (giữ thụt lề khối gốc) `      perform iam._idempotency_store('tenant.invitation.<op>', v_hash, p_idempotency_key, v_payload_hash, v_result);`

- [ ] **Step 7: Chạy test, xác nhận pass.**

- [ ] **Step 8: Dừng — tóm tắt.** Đề xuất commit: `refactor(iam): onboarding and invitation rpcs use idempotency_records`.

---

### Task 3: 4 lệnh còn lại (file owner)

**Files:**
- Modify: test file + `20260916007_…`, `20260811012_…`, `20260820002_…`, `20260911006_…`

- [ ] **Step 1: Thêm test (fail)**

```dart
  group('platform idempotency', () {
    test('uses idempotency_records', () => _expectUsesIdempotencyRecords(const {
          'iam.activate_tenant': ('20260916007_iam_patch_activate_tenant_default_store_scope.sql', 'tenant.activate'),
          'iam.transfer_platform_tenant_ownership': ('20260811012_iam_platform_transfer_ownership.sql', 'tenant.ownership.transfer'),
          'iam.suspend_platform_user': ('20260820002_iam_platform_user_suspend_state_changed_fix.sql', 'platform_user.suspend'),
          'iam.reinvite_provisioning_owner': ('20260911006_iam_reinvite_provisioning_owner.sql', 'tenant.owner.reinvite'),
        }));
  });
```

- [ ] **Step 2: Chạy test, xác nhận fail.**

- [ ] **Step 3: `activate_tenant`** (`20260916007_…`)
1. `declare`: `  v_existing iam.tenant_activation_operations;` → `  v_existing iam.idempotency_records;`
2. Thay khối `select * into v_existing from iam.tenant_activation_operations o where o.tenant_id = p_tenant_id and o.idempotency_key = p_idempotency_key; if found then … return v_existing.result; end if;` bằng:
```sql
  v_existing := iam._idempotency_find('tenant.activate', p_tenant_id::text, p_idempotency_key, v_payload_hash);
  if v_existing.idempotency_key is not null then
    return v_existing.result;
  end if;
```
3. Thay khối `insert into iam.tenant_activation_operations ( tenant_id, idempotency_key, payload_hash, result ) values ( p_tenant_id, p_idempotency_key, v_payload_hash, v_result );` bằng `  perform iam._idempotency_store('tenant.activate', p_tenant_id::text, p_idempotency_key, v_payload_hash, v_result);`

- [ ] **Step 4: `transfer_platform_tenant_ownership`** (`20260811012_…`)
1. `declare`: `  v_existing text;` → `  v_existing iam.idempotency_records;`
2. Thay:
```sql
  select payload_fingerprint into v_existing
  from iam.ownership_transfer_operations where idempotency_key = p_idempotency_key;
  if v_existing is not null then
    if v_existing <> v_fp then raise exception 'IDEMPOTENCY_CONFLICT'; end if;
    return;
  end if;
```
bằng:
```sql
  v_existing := iam._idempotency_find('tenant.ownership.transfer', 'platform', p_idempotency_key, v_fp);
  if v_existing.idempotency_key is not null then
    return;
  end if;
```
3. Thay:
```sql
  insert into iam.ownership_transfer_operations(
    idempotency_key, tenant_id, new_owner_user_id, payload_fingerprint
  ) values (p_idempotency_key, p_tenant_id, p_new_owner_user_id, v_fp);
```
bằng `  perform iam._idempotency_store('tenant.ownership.transfer', 'platform', p_idempotency_key, v_fp, null);`

- [ ] **Step 5: `suspend_platform_user`** (`20260820002_…`)
1. `declare`: `  v_existing text;` → `  v_existing iam.idempotency_records;`
2. Thay:
```sql
  select payload_fingerprint into v_existing
  from iam.platform_user_lifecycle_operations
  where idempotency_key = p_idempotency_key;
  if v_existing is not null then
    if v_existing <> v_fp then
      raise exception 'IDEMPOTENCY_CONFLICT';
    end if;
    return;
  end if;
```
bằng:
```sql
  v_existing := iam._idempotency_find('platform_user.suspend', 'platform', p_idempotency_key, v_fp);
  if v_existing.idempotency_key is not null then
    return;
  end if;
```
3. Thay:
```sql
  insert into iam.platform_user_lifecycle_operations(
    idempotency_key, user_id, action, payload_fingerprint
  ) values (p_idempotency_key, p_user_id, 'suspend', v_fp);
```
bằng `  perform iam._idempotency_store('platform_user.suspend', 'platform', p_idempotency_key, v_fp, null);`

- [ ] **Step 6: `reinvite_provisioning_owner`** (`20260911006_…`)
1. `declare`: `  v_existing jsonb;` → `  v_existing iam.idempotency_records;`
2. Thay:
```sql
  select result into v_existing
  from iam.provisioning_owner_reinvite_operations
  where idempotency_key = p_idempotency_key;

  if v_existing is not null then
    return v_existing;
  end if;
```
bằng:
```sql
  v_existing := iam._idempotency_find('tenant.owner.reinvite', 'platform', p_idempotency_key, null);
  if v_existing.idempotency_key is not null then
    return v_existing.result;
  end if;
```
3. Thay:
```sql
  insert into iam.provisioning_owner_reinvite_operations (
    idempotency_key, tenant_id, result
  )
  values (p_idempotency_key, p_tenant_id, v_result);
```
bằng `  perform iam._idempotency_store('tenant.owner.reinvite', 'platform', p_idempotency_key, null, v_result);`

- [ ] **Step 7: Chạy test, xác nhận pass.**

- [ ] **Step 8: Dừng — tóm tắt.** Đề xuất commit: `refactor(iam): platform rpcs use idempotency_records`.

---

### Task 4: Dart — xoá phần get/retry onboarding operation

**Interfaces:**
- Produces: không còn `GetTenantOnboardingOperationQuery`, `RetryTenantOnboardingOperationCommand`, `TenantOnboardingOperationDto`, `TenantOnboardingOperationStatus`, method port/gateway get/retry, scenario `onboardingPartialFailure`, `onboardingResumeOk`.

- [ ] **Step 1: Xác nhận phạm vi**

Run: `grep -rnE "TenantOnboardingOperation|getTenantOnboardingOperation|retryTenantOnboardingOperation|onboardingPartialFailure|onboardingResumeOk" modules apps packages --include='*.dart' | grep -vE '/build/|\.dart_tool|\.g\.dart'`
Expected: chỉ các file ở File Structure. Có file khác → dừng, báo user.

- [ ] **Step 2: Xoá file application** — `get_tenant_onboarding_operation_query.dart`, `get_tenant_onboarding_operation_query_handler.dart`, `retry_tenant_onboarding_operation_command.dart`, `retry_tenant_onboarding_operation_command_handler.dart`, `retry_tenant_onboarding_operation_command_validator.dart`, `tenant_onboarding_operation_dto.dart`, `tenant_onboarding_operation_status.dart` (dưới `modules/iam/application/lib/src/platform/`).

- [ ] **Step 3: Bỏ export, port, gateway**
1. `modules/iam/application/lib/application.dart`: xoá 7 dòng `export` tới các file Step 2.
2. `modules/iam/application/lib/src/ports/i_platform_admin_gateway.dart`: xoá `import '../platform/shared/tenant_onboarding_operation_dto.dart';` và 2 khai báo `getTenantOnboardingOperation`, `retryTenantOnboardingOperation`.
3. `modules/iam/infrastructure/lib/src/domain/platform/supabase_platform_admin_gateway.dart`: xoá 2 override get/retry và `_mapOnboardingOperation`.

- [ ] **Step 4: Fake + test**
1. `fake_iam_scenario.dart`: xoá `onboardingPartialFailure,`, `onboardingResumeOk,`.
2. `fake_iam_module.dart`: xoá 4 import (dto, status, query, command); field `_onboardingOps`; 2 nhánh switch get/retry; 2 method `_handleGetOnboardingOperation`, `_handleRetryOnboardingOperation`.
3. `test/support/stub_platform_admin_gateway.dart`: xoá 2 override get/retry.
4. `test/scn_e01_u03_fr01_01_create_tenant_onboarding_test.dart`: trong `_IdempotentPlatformGateway` xoá field `operation` + 2 override; xoá test `'get + retry onboarding operation'`.
5. `test/iam_contract_fake_scenario_matrix_test.dart`: xoá đoạn từ `final partial = FakeIamModule(` tới `expect(resumed.status, TenantOnboardingOperationStatus.completed);`.

- [ ] **Step 5: Codegen** — `cd modules/iam/infrastructure && dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 6: Phân tích + test**
- `cd modules/iam/application && dart analyze && dart test`
- `cd modules/iam/infrastructure && dart analyze && dart test test/supabase_platform_admin_gateway_onboarding_test.dart`
- `cd apps/admin && flutter analyze`

Expected: không lỗi mới; test PASS.

- [ ] **Step 7: Dừng — tóm tắt.** Đề xuất commit: `refactor(iam): remove dead onboarding operation tracking from Dart`.

---

### Task 5: Kiểm chứng

- [ ] **Step 1: Grep** — `grep -rnE "iam\.(onboarding_operations|tenant_invitation_operations|tenant_invitation_mutate_operations|tenant_invitation_token_operations|tenant_activation_operations|ownership_transfer_operations|platform_user_lifecycle_operations|provisioning_owner_reinvite_operations)\b" supabase/migrations/*.sql`
Expected: chỉ trong thân hàm plpgsql bản cũ (không phải file owner).

- [ ] **Step 2: SQL contract test**
Run: `cd modules/iam/infrastructure && dart test test/iam_refactor_12_idempotency_records_sql_contract_test.dart test/iam_create_tenant_onboarding_new_owner_sql_contract_test.dart test/iam_tenant_invitation_create_sql_contract_test.dart test/iam_tenant_invitation_resend_revoke_sql_contract_test.dart test/iam_tenant_invitation_acceptance_sql_contract_test.dart test/iam_tenant_readiness_sql_contract_test.dart`
Expected: PASS; sửa assertion cũ kiểm tra `Touches` có get/retry, hoặc tên bảng `*_operations` (trừ baseline fail sẵn).

- [ ] **Step 3: Policy** — `dart run tools/vet45_supabase_migrate/bin/seed_registry.dart --write` rồi `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart --strict` → OK; `REGISTRY.yaml` có `_idempotency_find`, `_idempotency_store` (→ `20260811005`), không còn get/retry onboarding.

- [ ] **Step 4: Tiến độ spec** — dòng bảng 12 README: `… · 🧪 Đã sửa migration gốc, chờ reset`.

- [ ] **Step 5: Dừng — user reset + smoke test**

Sau `supabase db reset` (gửi lặp cùng `idempotency_key`):
1. Onboarding lặp → cùng `tenant_id`, không tạo tổ chức thứ 2.
2. Mời staff lặp cùng email → cùng lời mời; cùng key khác email → `IDEMPOTENCY_CONFLICT`.
3. Gửi lại / thu hồi lặp → không gửi mail lần 2.
4. Accept lặp → không tạo membership thứ 2.
5. Kích hoạt, chuyển chủ, tạm ngừng user lặp → không thực thi lần 2.
```sql
select operation, scope_id, idempotency_key, payload_hash is not null as has_hash, result is not null as has_result, created_at
from iam.idempotency_records order by created_at desc limit 20;
```
Đề xuất commit: `test(iam): verify idempotency refactor against original migrations`.
