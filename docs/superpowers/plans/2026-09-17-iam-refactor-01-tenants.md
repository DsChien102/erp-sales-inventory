# IAM refactor — Bảng 1 `iam.tenants` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thu gọn `iam.tenants` từ 24 xuống 17 cột (gộp `name`→`display_name`, `suspended_*`/`closed_*`→bộ cột trạng thái chung, bỏ `code`, `created_by_user_id`) bằng cách **sửa trực tiếp migration gốc**, không đổi chữ ký RPC hay key JSON.

**Architecture:** Task 1 sửa DDL tại migration tạo cột (foundation, `20260811010`, `20260811015`). Task 2–4 sửa định nghĩa **cuối cùng** của 21 hàm tại file owner (`REGISTRY.yaml`). Task 5 kiểm chứng: grep, SQL contract test, verify-policy; user `supabase db reset`.

**Tech Stack:** PostgreSQL/Supabase plpgsql; Dart `package:test` (SQL contract test).

**Spec:** [01-tenants.md](../specs/iam-schema-refactor/01-tenants.md) · Quy ước: [README §Quy ước implement](../specs/iam-schema-refactor/README.md#quy-ước-implement-sửa-trực-tiếp-migration-gốc)

## Global Constraints

- Tuân thủ **Quy ước implement** trong README spec (sửa file gốc, không `_drafts/`, không `drop column`).
- Không đổi chữ ký RPC; không đổi key JSON (`name`, `code`, `suspended_at`, `suspend_reason`, `suspended_by`, `closed_at`, `close_reason`, `closed_by` vẫn trả).
- Công thức key cũ: `name` = `display_name`; `code` = `left(id::text, 8)`; `suspended_*` = cột chung khi `status = 'suspended'`; `closed_*` = cột chung khi `status = 'closed'`.
- Restore: `status_changed_at = now()`, `status_changed_by = v_actor`, `status_reason = null`.
- Plan đầu tiên của chuỗi (thứ tự 1 → 2 → 3 → 4 → 6 → 8 → 12).
- Không promote, **không `git commit`** — cuối task tóm tắt + đề xuất commit rồi dừng.
- Trước khi sửa hàm: `node .gitnexus/run.cjs impact "<tên>" --direction upstream --repo .` (hàm SQL → `UNKNOWN`, dựa vào khảo sát).

## Khảo sát

**Câu lệnh chạy trực tiếp tham chiếu cột bị bỏ** (phải sửa, nếu không reset lỗi):

| File | Câu lệnh |
|---|---|
| `20260630000001_iam_foundation.sql` | `create table iam.tenants (… name text not null …)` |
| `20260811010_iam_platform_tenants_read.sql` | `add column if not exists code`, `suspended_at`, `suspend_reason`, `suspended_by`, `closed_at`, `close_reason`, `closed_by` |
| `20260811015_iam_tenant_profile_legal.sql` | `add column if not exists created_by_user_id`; `update iam.tenants set display_name = coalesce(display_name, name) …` |

**Định nghĩa cuối (file owner) của 21 hàm:**

| RPC | File owner |
|---|---|
| `create_tenant_onboarding` | `20260916004_iam_patch_onboarding_default_store_scope.sql` |
| `update_tenant_profile` | `20260826002_iam_tenant_audit_history_v2_payloads.sql` |
| `activate_tenant` | `20260916007_iam_patch_activate_tenant_default_store_scope.sql` |
| `suspend_platform_tenant`, `restore_platform_tenant` | `20260811011_iam_platform_tenant_lifecycle.sql` |
| `_tenant_json` | `20260811015_iam_tenant_profile_legal.sql` |
| `get_platform_tenant` | `20260911003_iam_get_platform_tenant_owner_from_invitation.sql` |
| `search_platform_tenants` | `20260811010_iam_platform_tenants_read.sql` |
| `list_user_tenants`, `list_accessible_tenants` | `20260811014_iam_tenant_membership_lifecycle.sql` |
| `get_tenant_context`, `switch_tenant_context` | `20260811024_iam_patch_owner_role_canonicalization.sql` |
| `_ensure_tenant_default_store` | `20260916001_iam_ensure_default_store_scope_helpers.sql` |
| `accept_invitation` | `20260916006_iam_patch_accept_invitation_default_store_scope.sql` |
| `inspect_invitation_token` | `20260911005_iam_hybrid_owner_accept_decline_unwind.sql` |
| `get_platform_user` | `20260911002_iam_patch_search_phone_status_casts.sql` |
| `get_tenant_readiness` | `20260811016_iam_tenant_readiness_activate.sql` |
| `get_platform_audit_log`, `search_tenant_audit_logs_v2`, `get_tenant_audit_log`, `search_platform_audit_logs` | `20260826004_iam_audit_logs_v2_rebuild.sql` |

Không sửa: `upsert_legal_profile`, `bootstrap_owner(uuid, text)`, module ngoài IAM; định nghĩa plpgsql cũ hơn ở các file khác.

**Thay đổi hành vi nhỏ đã chấp nhận:** tìm kiếm theo mã khớp `left(id, 8)`; key `code` trong snapshot audit có giá trị thay vì null.

## File Structure

| File | Thay đổi |
|---|---|
| Modify 3 migration DDL + 16 migration owner (bảng Khảo sát) | Sửa tại chỗ |
| Create `modules/iam/infrastructure/test/iam_refactor_01_tenants_sql_contract_test.dart` | SQL contract test |
| Modify `docs/superpowers/specs/iam-schema-refactor/README.md` | Tiến độ |

Chạy test: `cd modules/iam/infrastructure && dart test test/iam_refactor_01_tenants_sql_contract_test.dart`

---

### Task 1: DDL tại migration gốc

**Files:**
- Create: `modules/iam/infrastructure/test/iam_refactor_01_tenants_sql_contract_test.dart`
- Modify: `supabase/migrations/20260630000001_iam_foundation.sql`
- Modify: `supabase/migrations/20260811010_iam_platform_tenants_read.sql`
- Modify: `supabase/migrations/20260811015_iam_tenant_profile_legal.sql`

**Interfaces:**
- Produces: sau reset, `iam.tenants` có đúng 17 cột (spec §3), gồm `status_changed_by uuid`, `status_reason text`, `display_name text not null`. Test helper `_readMigration`, `_lastFunctionBlock`, `_legacyTenantColumnRef`.

- [ ] **Step 1: Viết test (fail)**

```dart
import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — IAM refactor bảng 1 `iam.tenants`
/// (docs/superpowers/specs/iam-schema-refactor/01-tenants.md).
void main() {
  group('tenants DDL in original migrations', () {
    test('foundation creates display_name instead of name', () {
      final sql = _readMigration('20260630000001_iam_foundation.sql');
      final table = sql.substring(
        sql.indexOf('create table if not exists iam.tenants ('),
        sql.indexOf(');', sql.indexOf('create table if not exists iam.tenants (')),
      );
      expect(table, contains('display_name text not null,'));
      expect(table, isNot(contains('name text not null')));
    });

    test('platform tenants read no longer adds legacy columns', () {
      final sql = _readMigration('20260811010_iam_platform_tenants_read.sql');
      for (final column in const [
        'code',
        'suspended_at',
        'suspend_reason',
        'suspended_by',
        'closed_at',
        'close_reason',
        'closed_by',
      ]) {
        expect(sql, isNot(contains('add column if not exists $column ')), reason: column);
      }
    });

    test('tenant profile adds shared status columns, no created_by_user_id, no name backfill', () {
      final sql = _readMigration('20260811015_iam_tenant_profile_legal.sql');
      expect(sql, contains('add column if not exists status_changed_by uuid,'));
      expect(sql, contains('add column if not exists status_reason text,'));
      expect(sql, isNot(contains('created_by_user_id')));
      expect(sql, isNot(contains('coalesce(display_name, name)')));
    });
  });
}

/// Column refs on tenant variables that must disappear from final RPC bodies.
final RegExp _legacyTenantColumnRef = RegExp(
  r'\b(t|v_tenant|p_tenant|v_row)\.(name|code|suspended_at|suspend_reason|'
  r'suspended_by|closed_at|close_reason|closed_by|created_by_user_id)\b',
);

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

Run: `cd modules/iam/infrastructure && dart test test/iam_refactor_01_tenants_sql_contract_test.dart`
Expected: FAIL 3 test (nội dung migration chưa đổi).

- [ ] **Step 3: Sửa `20260630000001_iam_foundation.sql`**

Trong `create table if not exists iam.tenants (`: `  name text not null,` → `  display_name text not null,`

- [ ] **Step 4: Sửa `20260811010_iam_platform_tenants_read.sql`**

Xoá 7 câu lệnh (giữ `status`, `activated_at`, `updated_at`, `version`):
```sql
alter table iam.tenants
  add column if not exists code text;
```
```sql
alter table iam.tenants
  add column if not exists suspended_at timestamptz;

alter table iam.tenants
  add column if not exists suspend_reason text;

alter table iam.tenants
  add column if not exists suspended_by uuid;

alter table iam.tenants
  add column if not exists closed_at timestamptz;

alter table iam.tenants
  add column if not exists close_reason text;

alter table iam.tenants
  add column if not exists closed_by uuid;
```

- [ ] **Step 5: Sửa `20260811015_iam_tenant_profile_legal.sql`**

1. Trong `alter table iam.tenants add column …`: thay dòng `  add column if not exists created_by_user_id uuid,` bằng:
```sql
  add column if not exists status_changed_by uuid,
  add column if not exists status_reason text,
```
2. Xoá câu lệnh:
```sql
update iam.tenants
set display_name = coalesce(display_name, name)
where display_name is null;
```

- [ ] **Step 6: Chạy test, xác nhận pass** — Expected: PASS (3 test).

- [ ] **Step 7: Dừng — tóm tắt.** Đề xuất commit: `refactor(iam): tenants DDL uses display_name and shared status columns`.

---

### Task 2: RPC ghi tenant (file owner)

**Files:**
- Modify: `modules/iam/infrastructure/test/iam_refactor_01_tenants_sql_contract_test.dart`
- Modify: `20260916004_iam_patch_onboarding_default_store_scope.sql`, `20260826002_iam_tenant_audit_history_v2_payloads.sql`, `20260916007_iam_patch_activate_tenant_default_store_scope.sql`, `20260811011_iam_platform_tenant_lifecycle.sql` (thư mục `supabase/migrations/`)

**Interfaces:**
- Consumes: cột `status_changed_by`, `status_reason` (Task 1).
- Produces: 5 RPC cùng chữ ký, không đọc/ghi cột cũ.

- [ ] **Step 1: Thêm test (fail)**

```dart
  group('tenant write rpcs (final definitions)', () {
    const owners = {
      'iam.create_tenant_onboarding': '20260916004_iam_patch_onboarding_default_store_scope.sql',
      'iam.update_tenant_profile': '20260826002_iam_tenant_audit_history_v2_payloads.sql',
      'iam.activate_tenant': '20260916007_iam_patch_activate_tenant_default_store_scope.sql',
      'iam.suspend_platform_tenant': '20260811011_iam_platform_tenant_lifecycle.sql',
      'iam.restore_platform_tenant': '20260811011_iam_platform_tenant_lifecycle.sql',
    };

    String body(String fn) => _lastFunctionBlock(_readMigration(owners[fn]!), fn);

    test('no legacy tenant columns', () {
      for (final fn in owners.keys) {
        expect(body(fn), isNot(matches(_legacyTenantColumnRef)), reason: fn);
        expect(body(fn), isNot(contains('suspended_at')), reason: fn);
        expect(body(fn), isNot(contains('suspended_by')), reason: fn);
      }
    });

    test('onboarding inserts display_name and status columns', () {
      final b = body('iam.create_tenant_onboarding');
      expect(b, contains('insert into iam.tenants (\n    display_name,'));
      expect(b, contains('status_changed_at, status_changed_by, updated_at'));
    });

    test('update profile derives code and no longer mirrors name', () {
      final b = body('iam.update_tenant_profile');
      expect(b, isNot(contains('name = p_display_name')));
      expect(b, contains('left(v_row.id::text, 8)'));
    });

    test('activate / suspend / restore write shared status columns', () {
      expect(body('iam.activate_tenant'), contains('status_changed_by = auth.uid()'));
      expect(body('iam.suspend_platform_tenant'), contains('status_reason = trim(p_reason)'));
      expect(body('iam.restore_platform_tenant'), contains('status_reason = null'));
      expect(body('iam.restore_platform_tenant'), contains('status_changed_by = v_actor'));
    });
  });
```

- [ ] **Step 2: Chạy test, xác nhận fail** — Expected: group mới FAIL.

- [ ] **Step 3: `create_tenant_onboarding`** (file `20260916004_…`)

Thay khối insert:
```sql
  insert into iam.tenants (
    name, display_name, contact_email, contact_phone, contact_address_text,
    province_code, commune_code, status, updated_at
  )
  values (
    trim(p_org_name),
    coalesce(nullif(trim(coalesce(p_org_display_name, '')), ''), trim(p_org_name)),
    nullif(trim(coalesce(p_org_contact_email, '')), ''),
    nullif(trim(coalesce(p_org_contact_phone, '')), ''),
    nullif(trim(coalesce(p_org_contact_address_text, '')), ''),
    nullif(trim(coalesce(p_org_province_code, '')), ''),
    nullif(trim(coalesce(p_org_commune_code, '')), ''),
    'provisioning',
    v_now
  )
  returning id into v_tenant_id;
```
bằng:
```sql
  insert into iam.tenants (
    display_name,
    contact_email, contact_phone, contact_address_text,
    province_code, commune_code, status,
    status_changed_at, status_changed_by, updated_at
  )
  values (
    coalesce(nullif(trim(coalesce(p_org_display_name, '')), ''), trim(p_org_name)),
    nullif(trim(coalesce(p_org_contact_email, '')), ''),
    nullif(trim(coalesce(p_org_contact_phone, '')), ''),
    nullif(trim(coalesce(p_org_contact_address_text, '')), ''),
    nullif(trim(coalesce(p_org_province_code, '')), ''),
    nullif(trim(coalesce(p_org_commune_code, '')), ''),
    'provisioning',
    v_now, v_actor, v_now
  )
  returning id into v_tenant_id;
```

- [ ] **Step 4: `update_tenant_profile`** (file `20260826002_…`, định nghĩa cuối)

1. Xoá dòng `    name = p_display_name,` trong `update iam.tenants set`.
2. Thay:
```sql
    p_target_secondary_identifier => v_row.code,
    p_target_snapshot => jsonb_build_object(
      'display_name', v_row.display_name,
      'subject_code', v_row.code,
      'secondary_label', v_row.code
    ),
```
bằng:
```sql
    p_target_secondary_identifier => left(v_row.id::text, 8),
    p_target_snapshot => jsonb_build_object(
      'display_name', v_row.display_name,
      'subject_code', left(v_row.id::text, 8),
      'secondary_label', left(v_row.id::text, 8)
    ),
```

- [ ] **Step 5: `activate_tenant`** (file `20260916007_…`)

Trong `update iam.tenants set …`, sau dòng `    status_changed_at = now(),` thêm:
```sql
    status_changed_by = auth.uid(),
    status_reason = null,
```

- [ ] **Step 6: `suspend_platform_tenant`** (file `20260811011_…`)

Thay:
```sql
  set status = 'suspended',
      suspended_at = now(),
      suspend_reason = trim(p_reason),
      suspended_by = v_actor,
```
bằng:
```sql
  set status = 'suspended',
      status_changed_at = now(),
      status_changed_by = v_actor,
      status_reason = trim(p_reason),
```

- [ ] **Step 7: `restore_platform_tenant`** (file `20260811011_…`)

Thay:
```sql
  set status = 'active',
      suspended_at = null,
      suspend_reason = null,
      suspended_by = null,
```
bằng:
```sql
  set status = 'active',
      status_changed_at = now(),
      status_changed_by = v_actor,
      status_reason = null,
```

- [ ] **Step 8: Chạy test, xác nhận pass** — Expected: PASS.

- [ ] **Step 9: Dừng — tóm tắt.** Đề xuất commit: `refactor(iam): tenant write rpcs use shared status columns`.

---

### Task 3: RPC đọc tenant / context (file owner)

**Files:**
- Modify: test file
- Modify: `20260811015_iam_tenant_profile_legal.sql`, `20260911003_iam_get_platform_tenant_owner_from_invitation.sql`, `20260811010_iam_platform_tenants_read.sql`, `20260811014_iam_tenant_membership_lifecycle.sql`, `20260811024_iam_patch_owner_role_canonicalization.sql`, `20260916001_iam_ensure_default_store_scope_helpers.sql`

**Interfaces:**
- Produces: 8 RPC cùng chữ ký và key JSON / cột trả về.

- [ ] **Step 1: Thêm test (fail)**

```dart
  group('tenant read/context rpcs (final definitions)', () {
    const owners = {
      'iam._tenant_json': '20260811015_iam_tenant_profile_legal.sql',
      'iam.get_platform_tenant': '20260911003_iam_get_platform_tenant_owner_from_invitation.sql',
      'iam.search_platform_tenants': '20260811010_iam_platform_tenants_read.sql',
      'iam.list_user_tenants': '20260811014_iam_tenant_membership_lifecycle.sql',
      'iam.list_accessible_tenants': '20260811014_iam_tenant_membership_lifecycle.sql',
      'iam.get_tenant_context': '20260811024_iam_patch_owner_role_canonicalization.sql',
      'iam.switch_tenant_context': '20260811024_iam_patch_owner_role_canonicalization.sql',
      'iam._ensure_tenant_default_store': '20260916001_iam_ensure_default_store_scope_helpers.sql',
    };

    String body(String fn) => _lastFunctionBlock(_readMigration(owners[fn]!), fn);

    test('no legacy tenant columns', () {
      for (final fn in owners.keys) {
        expect(body(fn), isNot(matches(_legacyTenantColumnRef)), reason: fn);
      }
    });

    test('get_platform_tenant derives legacy keys', () {
      final b = body('iam.get_platform_tenant');
      expect(b, contains("'name', v_tenant.display_name"));
      expect(b, contains("'code', left(v_tenant.id::text, 8)"));
      expect(b, contains("'suspended_at', case when v_tenant.status = 'suspended' then v_tenant.status_changed_at end"));
      expect(b, contains("'close_reason', case when v_tenant.status = 'closed' then v_tenant.status_reason end"));
    });

    test('search keeps name/code output columns', () {
      final b = body('iam.search_platform_tenants');
      expect(b, contains('t.display_name::text as name'));
      expect(b, contains('left(t.id::text, 8)::text as code'));
    });
  });
```

- [ ] **Step 2: Chạy test, xác nhận fail** — Expected: group mới FAIL.

- [ ] **Step 3: `_tenant_json`** (`20260811015_…`): `    'display_name', coalesce(p_tenant.display_name, p_tenant.name),` → `    'display_name', p_tenant.display_name,`

- [ ] **Step 4: `get_platform_tenant`** (`20260911003_…`)

(a) Thay khối select tenant:
```sql
  select
    t.id,
    t.name,
    coalesce(t.code, left(t.id::text, 8)) as code,
    coalesce(t.status, 'active') as status,
    coalesce(t.version, 1) as version,
    t.created_at,
    t.updated_at,
    t.activated_at,
    t.suspended_at,
    t.suspend_reason,
    t.suspended_by,
    t.closed_at,
    t.close_reason,
    t.closed_by
  into v_tenant
```
bằng:
```sql
  select
    t.id,
    t.display_name,
    coalesce(t.status, 'active') as status,
    coalesce(t.version, 1) as version,
    t.created_at,
    t.updated_at,
    t.activated_at,
    t.status_changed_at,
    t.status_changed_by,
    t.status_reason
  into v_tenant
```

(b) Trong `return jsonb_build_object(`, thay đoạn từ `    'name', v_tenant.name,` tới hết khối `'closed_by', ( … ),` bằng:
```sql
    'name', v_tenant.display_name,
    'code', left(v_tenant.id::text, 8),
    'status', v_tenant.status,
    'version', v_tenant.version,
    'created_at', v_tenant.created_at,
    'activated_at', v_tenant.activated_at,
    'last_activity_at', coalesce(v_tenant.updated_at, v_tenant.activated_at, v_tenant.created_at),
    'suspended_at', case when v_tenant.status = 'suspended' then v_tenant.status_changed_at end,
    'suspend_reason', case when v_tenant.status = 'suspended' then v_tenant.status_reason end,
    'suspended_by', (
      select coalesce(
        nullif(
          trim(concat_ws(' ', u.raw_user_meta_data->>'last_name', u.raw_user_meta_data->>'first_name')),
          ''
        ),
        u.email::text
      )
      from auth.users u
      where v_tenant.status = 'suspended'
        and u.id = v_tenant.status_changed_by
    ),
    'closed_at', case when v_tenant.status = 'closed' then v_tenant.status_changed_at end,
    'close_reason', case when v_tenant.status = 'closed' then v_tenant.status_reason end,
    'closed_by', (
      select coalesce(
        nullif(
          trim(concat_ws(' ', u.raw_user_meta_data->>'last_name', u.raw_user_meta_data->>'first_name')),
          ''
        ),
        u.email::text
      )
      from auth.users u
      where v_tenant.status = 'closed'
        and u.id = v_tenant.status_changed_by
    ),
```

- [ ] **Step 5: `search_platform_tenants`** (`20260811010_…`)
1. `      t.name::text,` → `      t.display_name::text as name,`
2. `      coalesce(t.code, left(t.id::text, 8))::text as code,` → `      left(t.id::text, 8)::text as code,`
3. `        or t.name ilike '%' || p_query || '%'` → `        or t.display_name ilike '%' || p_query || '%'`
4. `        or coalesce(t.code, '') ilike '%' || p_query || '%'` → `        or left(t.id::text, 8) ilike '%' || p_query || '%'`

- [ ] **Step 6: `list_user_tenants`, `list_accessible_tenants`** (`20260811014_…`)
- `  select t.id, t.name, m.role` → `  select t.id, t.display_name, m.role`
- `  select t.id, t.name, m.role, t.status, m.is_owner` → `  select t.id, t.display_name, m.role, t.status, m.is_owner`

- [ ] **Step 7: `get_tenant_context`, `switch_tenant_context`** (`20260811024_…`): trong cả hai, `t.name, coalesce(t.status, 'active')` → `t.display_name, coalesce(t.status, 'active')`.

- [ ] **Step 8: `_ensure_tenant_default_store`** (`20260916001_…`): `coalesce(nullif(trim(t.display_name), ''), nullif(trim(t.name), ''), 'Default Store')` → `coalesce(nullif(trim(t.display_name), ''), 'Default Store')`.

- [ ] **Step 9: Chạy test, xác nhận pass.**

- [ ] **Step 10: Dừng — tóm tắt.** Đề xuất commit: `refactor(iam): tenant read rpcs derive legacy keys`.

---

### Task 4: RPC invitation / audit / user / readiness (file owner)

**Files:**
- Modify: test file
- Modify: `20260916006_iam_patch_accept_invitation_default_store_scope.sql`, `20260911005_iam_hybrid_owner_accept_decline_unwind.sql`, `20260911002_iam_patch_search_phone_status_casts.sql`, `20260811016_iam_tenant_readiness_activate.sql`, `20260826004_iam_audit_logs_v2_rebuild.sql`

- [ ] **Step 1: Thêm test (fail)**

```dart
  group('tenant name/code consumers (final definitions)', () {
    const owners = {
      'iam.accept_invitation': '20260916006_iam_patch_accept_invitation_default_store_scope.sql',
      'iam.inspect_invitation_token': '20260911005_iam_hybrid_owner_accept_decline_unwind.sql',
      'iam.get_platform_user': '20260911002_iam_patch_search_phone_status_casts.sql',
      'iam.get_tenant_readiness': '20260811016_iam_tenant_readiness_activate.sql',
      'iam.get_platform_audit_log': '20260826004_iam_audit_logs_v2_rebuild.sql',
      'iam.search_tenant_audit_logs_v2': '20260826004_iam_audit_logs_v2_rebuild.sql',
      'iam.get_tenant_audit_log': '20260826004_iam_audit_logs_v2_rebuild.sql',
      'iam.search_platform_audit_logs': '20260826004_iam_audit_logs_v2_rebuild.sql',
    };

    test('no legacy tenant columns', () {
      for (final entry in owners.entries) {
        expect(
          _lastFunctionBlock(_readMigration(entry.value), entry.key),
          isNot(matches(_legacyTenantColumnRef)),
          reason: entry.key,
        );
      }
    });

    test('accept_invitation derives tenant code from id', () {
      final b = _lastFunctionBlock(
        _readMigration(owners['iam.accept_invitation']!),
        'iam.accept_invitation',
      );
      expect('left(v_tenant.id::text, 8)'.allMatches(b).length, 6);
    });
  });
```

- [ ] **Step 2: Chạy test, xác nhận fail.**

- [ ] **Step 3: `accept_invitation`** (`20260916006_…`): thay **cả 6** chỗ `v_tenant.code` bằng `left(v_tenant.id::text, 8)`.

- [ ] **Step 4: `inspect_invitation_token`** (`20260911005_…`): `coalesce(v_tenant.name, '')` → `coalesce(v_tenant.display_name, '')`.

- [ ] **Step 5: `get_platform_user`** (`20260911002_…`): `        'tenant_name', t.name,` → `        'tenant_name', t.display_name,`.

- [ ] **Step 6: `get_tenant_readiness`** (`20260811016_…`): `coalesce(v_tenant.display_name, v_tenant.name, '') = ''` → `coalesce(v_tenant.display_name, '') = ''`.

- [ ] **Step 7: 4 hàm audit** (`20260826004_…`)
- `get_platform_audit_log`: `coalesce(t.name, a.target_type, '') as target_org_name` → `coalesce(t.display_name, a.target_type, '') as target_org_name`; `coalesce(t.code, a.target_id, left(coalesce(t.id::text, ''), 8)) as target_org_code` → `coalesce(a.target_id, left(coalesce(t.id::text, ''), 8)) as target_org_code`; trong khối tên hiển thị đối tượng `      t.name,` → `      t.display_name,`.
- `search_tenant_audit_logs_v2`: 2 chỗ `t.code ilike '%' || v_query || '%' or` → `left(t.id::text, 8) ilike '%' || v_query || '%' or`; `      t.code as t_code,` → `      left(t.id::text, 8) as t_code,`.
- `get_tenant_audit_log`: `    t.code as t_code,` → `    left(t.id::text, 8) as t_code,`.
- `search_platform_audit_logs`: `coalesce(t.name, '') as target_org_name` → `coalesce(t.display_name, '') as target_org_name`; `coalesce(t.code, left(coalesce(t.id::text, ''), 8)) as target_org_code` → `left(coalesce(t.id::text, ''), 8) as target_org_code`; `or coalesce(t.name, '') ilike` → `or coalesce(t.display_name, '') ilike`; `or coalesce(t.code, '') ilike '%' || p_action || '%'` → `or left(coalesce(t.id::text, ''), 8) ilike '%' || p_action || '%'`.

- [ ] **Step 8: Chạy test, xác nhận pass.**

- [ ] **Step 9: Dừng — tóm tắt.** Đề xuất commit: `refactor(iam): invitation/audit rpcs stop reading tenant name/code`.

---

### Task 5: Kiểm chứng toàn chuỗi

**Files:**
- Modify (nếu cần): SQL contract test cũ assert nội dung đã đổi
- Modify: `docs/superpowers/specs/iam-schema-refactor/README.md`

- [ ] **Step 1: Grep câu lệnh chạy trực tiếp**

Run: `grep -nE "add column if not exists (code|suspended_at|suspend_reason|suspended_by|closed_at|close_reason|closed_by|created_by_user_id)\b|coalesce\(display_name, name\)" supabase/migrations/*.sql`
Expected: không có kết quả.

Run: `grep -nE "iam\.tenants" supabase/migrations/*.sql | grep -E "\bname\b"`
Expected: không còn câu `create table`/`update`/`insert` ngoài thân hàm plpgsql bản cũ (xem cột kết quả; thân hàm cũ bỏ qua).

- [ ] **Step 2: SQL contract test IAM**

Run: `cd modules/iam/infrastructure && dart test test/iam_refactor_01_tenants_sql_contract_test.dart test/iam_tenant_readiness_sql_contract_test.dart test/iam_tenant_invitation_acceptance_sql_contract_test.dart test/iam_audit_read_sql_contract_test.dart test/iam_membership_owner_invariant_sql_contract_test.dart`
Expected: PASS. Nếu một test cũ fail vì assert chuỗi đã đổi có chủ đích (vd `t.name`, `suspended_at = null`), sửa assertion sang chuỗi mới tương ứng trong plan này. Không sửa các test thuộc baseline fail sẵn (README).

- [ ] **Step 3: Policy**

Run:
- `dart run tools/vet45_supabase_migrate/bin/seed_registry.dart --write`
- `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart --strict`

Expected: `verify_migration_policy: OK (no violations)`; `git diff supabase/migrations/REGISTRY.yaml` không đổi owner.

- [ ] **Step 4: Cập nhật tiến độ spec**

Dòng bảng 1 trong README spec:
```markdown
| 1 | `iam.tenants` | ✅ Đã chốt · 📝 Plan: [2026-09-17-iam-refactor-01-tenants](../../plans/2026-09-17-iam-refactor-01-tenants.md) · 🧪 Đã sửa migration gốc, chờ reset | [01-tenants.md](01-tenants.md) |
```

- [ ] **Step 5: Dừng — user reset + smoke test**

User chạy `supabase db reset` (chuỗi phải chạy hết không lỗi), rồi:
```sql
select column_name from information_schema.columns
where table_schema = 'iam' and table_name = 'tenants' order by ordinal_position;
```
Expected: 17 cột theo spec §3. Smoke test: onboarding tổ chức mới; admin xem danh sách/chi tiết tổ chức (tên, mã 8 ký tự); suspend → restore (lý do null sau restore); ERP chọn/chuyển tổ chức; audit log mở được.
Đề xuất commit: `test(iam): verify tenants refactor against original migrations`.
