# IAM refactor — Bảng 3 `iam.memberships` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thay `memberships.status` bằng `is_active` + `removed_at` (giữ contract JSON `status`), sửa 2 hàm unwind, thêm FK role, dọn kiểm tra role `'owner'`, bỏ index thừa, bảo đảm 1 owner / tenant — **sửa trực tiếp migration gốc**.

**Architecture:** Task 1 sửa DDL + câu lệnh chạy trực tiếp (`20260811010`, `20260811014`, `20260811024`, `20260820007`, `20260916003`) và thêm helper `iam._membership_status_code`. Task 2–5 sửa định nghĩa cuối của 30 hàm tại file owner theo bảng quy tắc. Task 6 kiểm chứng. Không đổi chữ ký RPC, không đổi Dart.

**Tech Stack:** PostgreSQL/Supabase plpgsql; Dart `package:test` (SQL contract test).

**Spec:** [03-memberships.md](../specs/iam-schema-refactor/03-memberships.md) · Quy ước: [README §Quy ước implement](../specs/iam-schema-refactor/README.md#quy-ước-implement-sửa-trực-tiếp-migration-gốc)

## Global Constraints

- Tuân thủ **Quy ước implement**. Chạy sau plan [1](2026-09-17-iam-refactor-01-tenants.md), [2](2026-09-17-iam-refactor-02-tenant-legal-profiles.md) — văn bản "trước" trong các bước đã bao gồm thay đổi của plan 1–2.
- Key JSON `status` vẫn trả `active|inactive|removed` qua `iam._membership_status_code(is_active, removed_at)`.
- Bảng quy tắc viết lại (alias membership: `m`, `om`, `membership`, `p_membership`, `v_row`, `v_target_row`, `v_existing_membership`, `v_membership`):

  | Cũ | Mới |
  |---|---|
  | `X.status = 'active'` / `coalesce(X.status, 'active') = 'active'` | `X.is_active` |
  | `X.status in ('active', 'inactive')` | `X.removed_at is null` |
  | `X.status = 'removed'` | `X.removed_at is not null` |
  | đọc `X.status` làm giá trị | `iam._membership_status_code(X.is_active, X.removed_at)` |
  | `insert iam.memberships (…, status, …) values (…, 'active', …)` | bỏ cột `status` + giá trị `'active'` |

- Dọn role `'owner'`: `(X.is_owner is true or X.role = 'owner')` → `X.is_owner is true`; `role in ('owner', 'store_owner')` → `role = 'store_owner'`; `p_role not in ('owner', 'store_owner')` → `p_role <> 'store_owner'`. Giữ `'initial_role_id', case when v_should_be_owner then 'owner' …`. (Plan 8 sẽ bỏ tiếp các kiểm tra `role = 'store_owner'` dùng như quyền chủ.)
- Không promote, **không `git commit`** — cuối task tóm tắt + đề xuất commit rồi dừng.
- Trước khi sửa hàm: `node .gitnexus/run.cjs impact "<tên>" --direction upstream --repo .` (hàm SQL → `UNKNOWN`).

## Khảo sát

**Câu lệnh chạy trực tiếp phải sửa:**

| File | Câu lệnh |
|---|---|
| `20260811010_iam_platform_tenants_read.sql` | `alter table iam.memberships add column if not exists is_owner …, add column if not exists status …` |
| `20260811014_iam_tenant_membership_lifecycle.sql` | `add column if not exists status`; `memberships_status_chk`; index `memberships_tenant_user_active_uidx` |
| `20260820007_iam_clear_stale_last_selected_tenant.sql` | `update iam.user_preferences … m.status is distinct from 'active'` |
| `20260916003_iam_backfill_default_store_scopes.sql` | khối `DO`: `where m.status = 'active'` (plan 6 xoá tiếp khối này) |
| `20260811024_iam_patch_owner_role_canonicalization.sql` | nơi thêm FK role (sau khi seed `store_owner`, xoá `manager`, backfill `owner`) |

**Định nghĩa cuối (file owner) — 30 hàm:**

| # | RPC | File owner | Chỗ sửa |
|---|---|---|---|
| 1 | `_mutate_membership_status` | `20260811014_iam_tenant_membership_lifecycle.sql` | status + owner |
| 2 | `_membership_detail_json` | `20260820004_iam_tenant_member_detail_user_info.sql` | status + owner |
| 3 | `_unwind_staff_precreate_membership` | `20260916005_iam_patch_invitation_membership_store_scope.sql` | unwind |
| 4 | `_unwind_provisioning_owner_membership` | `20260911005_iam_hybrid_owner_accept_decline_unwind.sql` | unwind |
| 5 | `transfer_platform_tenant_ownership` | `20260811012_iam_platform_transfer_ownership.sql` | 2 bước |
| 6 | `assign_member_role` | `20260820005_iam_assign_member_role_fix.sql` | status + owner |
| 7 | `has_permission` | `20260811024_iam_patch_owner_role_canonicalization.sql` | status |
| 8 | `_ensure_membership_default_store_scope` | `20260916001_iam_ensure_default_store_scope_helpers.sql` | status |
| 9 | `accept_invitation` | `20260916006_iam_patch_accept_invitation_default_store_scope.sql` | status + insert + owner |
| 10 | `create_tenant_invitation` | `20260916005_iam_patch_invitation_membership_store_scope.sql` | status + insert |
| 11 | `create_tenant_onboarding` | `20260916004_iam_patch_onboarding_default_store_scope.sql` | insert |
| 12 | `reinvite_provisioning_owner` | `20260911006_iam_reinvite_provisioning_owner.sql` | status + insert |
| 13 | `inspect_invitation_token` | `20260911005_iam_hybrid_owner_accept_decline_unwind.sql` | status + owner |
| 14 | `get_tenant_readiness` | `20260811016_iam_tenant_readiness_activate.sql` | status + owner |
| 15 | `bootstrap_owner` | `20260914001_iam_get_session_context_multi_tenant.sql` | status + owner |
| 16 | `get_session_context` | `20260914001_iam_get_session_context_multi_tenant.sql` | status + owner |
| 17 | `activate_tenant` | `20260916007_iam_patch_activate_tenant_default_store_scope.sql` | status + owner |
| 18 | `update_tenant_profile` | `20260826002_iam_tenant_audit_history_v2_payloads.sql` | status |
| 19 | `get_platform_tenant` | `20260911003_iam_get_platform_tenant_owner_from_invitation.sql` | status |
| 20 | `search_platform_tenants` | `20260811010_iam_platform_tenants_read.sql` | status |
| 21 | `list_accessible_tenants` | `20260811014_…` | status |
| 22 | `list_user_tenants` | `20260811014_…` | status |
| 23 | `list_platform_tenant_members` | `20260811010_…` | status |
| 24 | `list_tenant_members` | `20260820004_…` | status + owner |
| 25 | `get_tenant_member` | `20260820004_…` | status |
| 26 | `get_tenant_invitation` | `20260826001_iam_fix_utc_now_offset.sql` | status |
| 27 | `list_tenant_invitations` | `20260826001_…` | status |
| 28 | `list_assignable_invitation_roles` | `20260811024_…` | status |
| 29 | `get_tenant_audit_log` | `20260826004_iam_audit_logs_v2_rebuild.sql` | status |
| 30 | `search_tenant_audit_logs_v2` | `20260826004_…` | status |

Không sửa: `_cleanup_pending_profile_on_auth_user`, `get_tenant_context`/`switch_tenant_context`, `get_platform_user` (`v_row.status` là profile).

## File Structure

| File | Thay đổi |
|---|---|
| Modify migration theo bảng Khảo sát | Sửa tại chỗ |
| Create `modules/iam/infrastructure/test/iam_refactor_03_memberships_sql_contract_test.dart` | SQL contract test |
| Modify `docs/superpowers/specs/iam-schema-refactor/README.md` | Tiến độ |

Chạy test: `cd modules/iam/infrastructure && dart test test/iam_refactor_03_memberships_sql_contract_test.dart`

---

### Task 1: DDL, helper và câu lệnh chạy trực tiếp

**Files:**
- Create: `modules/iam/infrastructure/test/iam_refactor_03_memberships_sql_contract_test.dart`
- Modify: `20260811010_iam_platform_tenants_read.sql`, `20260811014_iam_tenant_membership_lifecycle.sql`, `20260811024_iam_patch_owner_role_canonicalization.sql`, `20260820007_iam_clear_stale_last_selected_tenant.sql`, `20260916003_iam_backfill_default_store_scopes.sql`

**Interfaces:**
- Produces: sau reset, `iam.memberships` có `is_active boolean not null default true`, `removed_at`, không có `status`; constraint `memberships_removed_inactive_chk`, `memberships_role_fkey`; index `memberships_one_owner_per_tenant_uidx`; hàm `iam._membership_status_code(boolean, timestamptz) returns text`. Test helper `_readMigration`, `_lastFunctionBlock`, `_legacyMembershipStatus`, `_ownerRoleLiteral`, `_expectRewritten`.

- [ ] **Step 1: Viết test (fail)**

```dart
import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — IAM refactor bảng 3 `iam.memberships`
/// (docs/superpowers/specs/iam-schema-refactor/03-memberships.md).
void main() {
  group('memberships DDL in original migrations', () {
    final lifecycle = _readMigration('20260811014_iam_tenant_membership_lifecycle.sql');

    test('adds is_active instead of status; no status check; no partial active index', () {
      expect(lifecycle, contains('add column if not exists is_active boolean not null default true,'));
      expect(lifecycle, isNot(contains("add column if not exists status text not null default 'active'")));
      expect(lifecycle, isNot(contains('memberships_status_chk')));
      expect(lifecycle, isNot(contains('memberships_tenant_user_active_uidx')));
    });

    test('removed/inactive check and one owner per tenant', () {
      expect(lifecycle, contains('check (removed_at is null or is_active = false)'));
      expect(
        lifecycle,
        contains(
          'create unique index if not exists memberships_one_owner_per_tenant_uidx\n'
          '  on iam.memberships (tenant_id)\n'
          '  where is_owner and removed_at is null;',
        ),
      );
    });

    test('defines status code helper', () {
      final body = _lastFunctionBlock(lifecycle, 'iam._membership_status_code');
      expect(body, contains("when p_removed_at is not null then 'removed'"));
      expect(body, contains("when p_is_active then 'active'"));
      expect(body, contains("else 'inactive'"));
    });

    test('platform tenants read no longer adds memberships.status', () {
      final sql = _readMigration('20260811010_iam_platform_tenants_read.sql');
      expect(sql, isNot(contains("add column if not exists status text not null default 'active';\n\ncreate or replace function iam.get_platform_tenant")));
      expect(sql, contains('alter table iam.memberships\n  add column if not exists is_owner boolean not null default false;'));
    });

    test('role FK after role catalog canonicalization', () {
      final sql = _readMigration('20260811024_iam_patch_owner_role_canonicalization.sql');
      expect(sql, contains('foreign key (role) references iam.role_definitions (code)'));
    });

    test('executed statements use is_active', () {
      expect(
        _readMigration('20260820007_iam_clear_stale_last_selected_tenant.sql'),
        contains('and m.is_active is not true'),
      );
      expect(
        _readMigration('20260916003_iam_backfill_default_store_scopes.sql'),
        isNot(contains('m.status')),
      );
    });
  });
}

/// Membership `status` column reads that must disappear from final RPC bodies.
final RegExp _legacyMembershipStatus = RegExp(
  r'\b(m|om|membership|p_membership|v_row|v_target_row|v_existing_membership|v_membership)\.status\b',
);

/// Legacy role checks (role `owner` no longer exists).
final RegExp _ownerRoleLiteral = RegExp(
  r"role\s*=\s*'owner'|\('owner',\s*'store_owner'\)",
);

void _expectRewritten(Map<String, String> ownerByFunction) {
  for (final entry in ownerByFunction.entries) {
    final body = _lastFunctionBlock(_readMigration(entry.value), entry.key);
    expect(body, isNot(matches(_legacyMembershipStatus)), reason: entry.key);
    expect(body, isNot(matches(_ownerRoleLiteral)), reason: entry.key);
    expect(body, isNot(matches(RegExp(r'\bstatus,\s*is_owner'))), reason: entry.key);
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

- [ ] **Step 3: `20260811010_iam_platform_tenants_read.sql`**

Thay:
```sql
alter table iam.memberships
  add column if not exists is_owner boolean not null default false,
  add column if not exists status text not null default 'active';
```
bằng:
```sql
alter table iam.memberships
  add column if not exists is_owner boolean not null default false;
```

- [ ] **Step 4: `20260811014_iam_tenant_membership_lifecycle.sql`**

1. Trong `alter table iam.memberships add column …`: `  add column if not exists status text not null default 'active',` → `  add column if not exists is_active boolean not null default true,`
2. Thay:
```sql
alter table iam.memberships drop constraint if exists memberships_status_chk;
alter table iam.memberships
  add constraint memberships_status_chk
  check (status in ('active', 'inactive', 'removed'));
```
bằng:
```sql
alter table iam.memberships drop constraint if exists memberships_removed_inactive_chk;
alter table iam.memberships
  add constraint memberships_removed_inactive_chk
  check (removed_at is null or is_active = false);
```
3. Thay:
```sql
drop index if exists iam.memberships_tenant_user_active_uidx;
create unique index memberships_tenant_user_active_uidx
  on iam.memberships (tenant_id, user_id)
  where status in ('active', 'inactive');
```
bằng:
```sql
create unique index if not exists memberships_one_owner_per_tenant_uidx
  on iam.memberships (tenant_id)
  where is_owner and removed_at is null;

create or replace function iam._membership_status_code(
  p_is_active boolean,
  p_removed_at timestamptz
)
returns text
language sql
immutable
set search_path = iam, pg_temp
as $$
  select case
    when p_removed_at is not null then 'removed'
    when p_is_active then 'active'
    else 'inactive'
  end;
$$;

revoke all on function iam._membership_status_code(boolean, timestamptz) from public, anon;
grant execute on function iam._membership_status_code(boolean, timestamptz) to authenticated;
```
4. Header `-- Touches:` thêm `, iam._membership_status_code`.

- [ ] **Step 5: `20260811024_iam_patch_owner_role_canonicalization.sql`**

Ngay sau câu `update iam.memberships set role = 'store_owner', updated_at = now() where role = 'owner';` thêm:
```sql

alter table iam.memberships
  drop constraint if exists memberships_role_fkey;
alter table iam.memberships
  add constraint memberships_role_fkey
  foreign key (role) references iam.role_definitions (code);
```

- [ ] **Step 6: `20260820007_iam_clear_stale_last_selected_tenant.sql`**

`      and m.status is distinct from 'active'` → `      and m.is_active is not true`

- [ ] **Step 7: `20260916003_iam_backfill_default_store_scopes.sql`**

`    where m.status = 'active'` → `    where m.is_active`

- [ ] **Step 8: Chạy test, xác nhận pass.**

- [ ] **Step 9: Dừng — tóm tắt.** Đề xuất commit: `refactor(iam): memberships DDL uses is_active/removed_at, role FK, one owner index`.

---

### Task 2: Hàm lõi membership (#1–8)

**Files:**
- Modify: test file + file owner #1–8

- [ ] **Step 1: Thêm test (fail)**

```dart
  group('core membership rpcs (final definitions)', () {
    const owners = {
      'iam._mutate_membership_status': '20260811014_iam_tenant_membership_lifecycle.sql',
      'iam._membership_detail_json': '20260820004_iam_tenant_member_detail_user_info.sql',
      'iam._unwind_staff_precreate_membership': '20260916005_iam_patch_invitation_membership_store_scope.sql',
      'iam._unwind_provisioning_owner_membership': '20260911005_iam_hybrid_owner_accept_decline_unwind.sql',
      'iam.transfer_platform_tenant_ownership': '20260811012_iam_platform_transfer_ownership.sql',
      'iam.assign_member_role': '20260820005_iam_assign_member_role_fix.sql',
      'iam.has_permission': '20260811024_iam_patch_owner_role_canonicalization.sql',
      'iam._ensure_membership_default_store_scope': '20260916001_iam_ensure_default_store_scope_helpers.sql',
    };
    String body(String fn) => _lastFunctionBlock(_readMigration(owners[fn]!), fn);

    test('rewritten per rules', () => _expectRewritten(owners));

    test('mutate writes is_active and removed_at', () {
      final b = body('iam._mutate_membership_status');
      expect(b, contains("set is_active = (p_target_status = 'active'),"));
      expect(b, contains("removed_at = case when p_target_status = 'removed' then v_now else null end,"));
      expect(b, contains('v_current_status := iam._membership_status_code(v_row.is_active, v_row.removed_at);'));
    });

    test('detail json keeps status and removed_at keys', () {
      final b = body('iam._membership_detail_json');
      expect(b, contains("'status', iam._membership_status_code(p_membership.is_active, p_membership.removed_at),"));
      expect(b, contains("'removed_at', p_membership.removed_at"));
    });

    test('unwinds deactivate, stamp removal and bump version', () {
      for (final fn in ['iam._unwind_staff_precreate_membership', 'iam._unwind_provisioning_owner_membership']) {
        expect(body(fn), contains('is_active = false'), reason: fn);
        expect(body(fn), contains('removed_at = v_now'), reason: fn);
        expect(body(fn), contains('status_changed_at = v_now'), reason: fn);
        expect(body(fn), contains('version = version + 1'), reason: fn);
      }
    });

    test('transfer clears old owner before setting new owner', () {
      final b = body('iam.transfer_platform_tenant_ownership');
      expect(b.indexOf('set is_owner = true'), greaterThan(b.indexOf('set is_owner = false')));
      expect(b.indexOf('set is_owner = false'), isNonNegative);
    });
  });
```

- [ ] **Step 2: Chạy test, xác nhận fail.**

- [ ] **Step 3: `_mutate_membership_status`** (`20260811014_…`)

1. `declare`: thêm `  v_current_status text;`
2. Khối kiểm tra caller: `      and m.status = 'active'` → `      and m.is_active`
3. Ngay sau khối `if v_row.version <> p_expected_version then … end if;` thêm:
```sql

  v_current_status := iam._membership_status_code(v_row.is_active, v_row.removed_at);
```
4. Trong 4 câu `if` so sánh trạng thái (`if v_row.status = 'removed'`, `… and v_row.status <> 'inactive'`, `… and v_row.status <> 'active'`, `… and v_row.status not in ('active', 'inactive')`) và dòng `'status', v_row.status,` trong `v_before`: thay `v_row.status` bằng `v_current_status`.
5. `  v_is_owner := (v_row.is_owner is true or v_row.role = 'owner');` → `  v_is_owner := (v_row.is_owner is true);`
6. Khối đếm owner: `      and (m.is_owner is true or m.role = 'owner')` → `      and m.is_owner is true`; `      and m.status = 'active';` → `      and m.is_active;`
7. Thay:
```sql
  update iam.memberships
  set status = p_target_status,
      version = version + 1,
      status_changed_at = v_now,
      removed_at = case when p_target_status = 'removed' then v_now else removed_at end,
      updated_at = v_now
```
bằng:
```sql
  update iam.memberships
  set is_active = (p_target_status = 'active'),
      removed_at = case when p_target_status = 'removed' then v_now else null end,
      version = version + 1,
      status_changed_at = v_now,
      updated_at = v_now
```
8. Hai dòng `'status', v_row.status,` **sau** câu update (audit after / kết quả): `v_row.status` → `iam._membership_status_code(v_row.is_active, v_row.removed_at)`.

- [ ] **Step 4: `_membership_detail_json`** (`20260820004_…`)
1. `  if (p_membership.is_owner is true or p_membership.role = 'owner') then` → `  if p_membership.is_owner is true then`
2. `      and (m.is_owner is true or m.role = 'owner')` → `      and m.is_owner is true`
3. `      and m.status = 'active';` → `      and m.is_active;`
4. `    'is_owner', (p_membership.is_owner is true or p_membership.role = 'owner'),` → `    'is_owner', (p_membership.is_owner is true),`
5. `    'status', p_membership.status,` → `    'status', iam._membership_status_code(p_membership.is_active, p_membership.removed_at),`

- [ ] **Step 5: `_unwind_staff_precreate_membership`** (`20260916005_…`)

Thay:
```sql
  update iam.memberships m
  set
    status = 'removed',
    updated_at = v_now
  where m.id = p_membership_id
    and coalesce(m.is_owner, false) is not true
    and coalesce(m.status, 'active') = 'active';
```
bằng:
```sql
  update iam.memberships m
  set
    is_active = false,
    removed_at = v_now,
    status_changed_at = v_now,
    version = version + 1,
    updated_at = v_now
  where m.id = p_membership_id
    and coalesce(m.is_owner, false) is not true
    and m.is_active;
```

- [ ] **Step 6: `_unwind_provisioning_owner_membership`** (`20260911005_…`)
1. `    and coalesce(m.status, 'active') = 'active'` → `    and m.is_active`
2. Thay:
```sql
  update iam.memberships
  set
    is_owner = false,
    status = 'removed',
    updated_at = v_now
  where id = v_membership_id;
```
bằng:
```sql
  update iam.memberships
  set
    is_owner = false,
    is_active = false,
    removed_at = v_now,
    status_changed_at = v_now,
    version = version + 1,
    updated_at = v_now
  where id = v_membership_id;
```

- [ ] **Step 7: `transfer_platform_tenant_ownership`** (`20260811012_…`)

Thay:
```sql
  update iam.memberships
  set is_owner = (user_id = p_new_owner_user_id)
  where tenant_id = p_tenant_id;
```
bằng:
```sql
  -- Clear first: memberships_one_owner_per_tenant_uidx checks each row immediately.
  update iam.memberships
  set is_owner = false,
      updated_at = now()
  where tenant_id = p_tenant_id
    and is_owner
    and user_id <> p_new_owner_user_id;

  update iam.memberships
  set is_owner = true,
      updated_at = now()
  where tenant_id = p_tenant_id
    and user_id = p_new_owner_user_id;
```

- [ ] **Step 8: `assign_member_role`** (`20260820005_…`)
1. 3 chỗ `m.status = 'active'` → `m.is_active` (giữ `;` nếu có).
2. 2 chỗ `(m.is_owner is true or m.role in ('owner', 'store_owner'))` → `(m.is_owner is true or m.role = 'store_owner')`.
3. `  if v_target_row.status = 'removed' then` → `  if v_target_row.removed_at is not null then`
4. Thay:
```sql
  if (v_target_row.is_owner is true or v_target_row.role in ('owner', 'store_owner'))
     and p_role not in ('owner', 'store_owner') then
```
bằng:
```sql
  if (v_target_row.is_owner is true or v_target_row.role = 'store_owner')
     and p_role <> 'store_owner' then
```
5. 3 chỗ `'status', v_target_row.status,` → `'status', iam._membership_status_code(v_target_row.is_active, v_target_row.removed_at),`

- [ ] **Step 9: `has_permission`** (`20260811024_…`): `  select m.role, m.is_owner, m.status` → `  select m.role, m.is_owner, iam._membership_status_code(m.is_active, m.removed_at)`

- [ ] **Step 10: `_ensure_membership_default_store_scope`** (`20260916001_…`): `  select m.status` → `  select iam._membership_status_code(m.is_active, m.removed_at)` (plan 6 xoá hàm này).

- [ ] **Step 11: Chạy test, xác nhận pass.**

- [ ] **Step 12: Dừng — tóm tắt.** Đề xuất commit: `refactor(iam): core membership rpcs use is_active state`.

---

### Task 3: Invitation / session (#9–16)

**Files:**
- Modify: test file + file owner #9–16

- [ ] **Step 1: Thêm test (fail)**

```dart
  group('invitation/session rpcs (final definitions)', () {
    const owners = {
      'iam.accept_invitation': '20260916006_iam_patch_accept_invitation_default_store_scope.sql',
      'iam.create_tenant_invitation': '20260916005_iam_patch_invitation_membership_store_scope.sql',
      'iam.create_tenant_onboarding': '20260916004_iam_patch_onboarding_default_store_scope.sql',
      'iam.reinvite_provisioning_owner': '20260911006_iam_reinvite_provisioning_owner.sql',
      'iam.inspect_invitation_token': '20260911005_iam_hybrid_owner_accept_decline_unwind.sql',
      'iam.get_tenant_readiness': '20260811016_iam_tenant_readiness_activate.sql',
      'iam.bootstrap_owner': '20260914001_iam_get_session_context_multi_tenant.sql',
      'iam.get_session_context': '20260914001_iam_get_session_context_multi_tenant.sql',
    };
    String body(String fn) => _lastFunctionBlock(_readMigration(owners[fn]!), fn);

    test('rewritten per rules', () => _expectRewritten(owners));

    test('membership inserts no longer write status', () {
      for (final fn in [
        'iam.accept_invitation',
        'iam.create_tenant_invitation',
        'iam.create_tenant_onboarding',
        'iam.reinvite_provisioning_owner',
      ]) {
        expect(body(fn), contains('tenant_id, user_id, role, is_owner, version, created_at, updated_at'), reason: fn);
      }
    });

    test('create invitation detects existing membership by removed_at', () {
      final b = body('iam.create_tenant_invitation');
      expect(b, contains('and m.removed_at is null'));
      expect(b, contains('if v_existing_membership.is_active then'));
    });

    test('inspect keeps owner initial_role_id output value', () {
      expect(body('iam.inspect_invitation_token'), contains("'initial_role_id', case when v_should_be_owner then 'owner'"));
    });
  });
```

- [ ] **Step 2: Chạy test, xác nhận fail.**

- [ ] **Step 3: `accept_invitation`** (`20260916006_…`)
1. 2 chỗ `coalesce(m.status, 'active') = 'active'` → `m.is_active`; 2 chỗ `m.status = 'active'` → `m.is_active`.
2. `        and (m.is_owner is true or m.role = 'owner')` → `        and m.is_owner is true`
3. Insert membership: `      tenant_id, user_id, role, status, is_owner, version, created_at, updated_at` → `      tenant_id, user_id, role, is_owner, version, created_at, updated_at`; `      v_inv.tenant_id, v_caller, v_effective_role, 'active', v_should_be_owner, 1, v_now, v_now` → `      v_inv.tenant_id, v_caller, v_effective_role, v_should_be_owner, 1, v_now, v_now`

- [ ] **Step 4: `create_tenant_invitation`** (`20260916005_…`)
1. `    and m.status = 'active'` (khối actor) → `    and m.is_active`
2. `    and m.status in ('active', 'inactive')` → `    and m.removed_at is null`
3. Thay:
```sql
    if v_existing_membership.status = 'active' then
      raise exception 'DUPLICATE_MEMBERSHIP';
    end if;
    if v_existing_membership.status = 'inactive' then
      raise exception 'MEMBERSHIP_INACTIVE';
    end if;
```
bằng:
```sql
    if v_existing_membership.is_active then
      raise exception 'DUPLICATE_MEMBERSHIP';
    end if;
    raise exception 'MEMBERSHIP_INACTIVE';
```
4. Insert membership: cột `    tenant_id, user_id, role, status, is_owner, version, created_at, updated_at` → `    tenant_id, user_id, role, is_owner, version, created_at, updated_at`; trong `values (` xoá dòng `    'active',` (ngay sau `    coalesce(v_role.code, 'staff'),`).

- [ ] **Step 5: `create_tenant_onboarding`** (`20260916004_…`): insert owner membership `    tenant_id, user_id, role, status, is_owner, version, created_at, updated_at` → bỏ `status, `; `    v_tenant_id, v_owner_user_id, 'store_owner', 'active', true, 1, v_now, v_now` → `    v_tenant_id, v_owner_user_id, 'store_owner', true, 1, v_now, v_now`.

- [ ] **Step 6: `reinvite_provisioning_owner`** (`20260911006_…`)
1. `      and coalesce(m.status, 'active') = 'active'` → `      and m.is_active`
2. Insert: bỏ `status, ` trong danh sách cột; `    p_tenant_id, v_owner_user_id, 'store_owner', 'active', true, 1, v_now, v_now` → `    p_tenant_id, v_owner_user_id, 'store_owner', true, 1, v_now, v_now`

- [ ] **Step 7: `inspect_invitation_token`** (`20260911005_…`): `      and m.status = 'active'` → `      and m.is_active`; `      and (m.is_owner is true or m.role = 'owner')` → `      and m.is_owner is true`. Giữ `'initial_role_id', case when v_should_be_owner then 'owner' …`.

- [ ] **Step 8: `get_tenant_readiness`** (`20260811016_…`): 2 chỗ `and (m.is_owner is true or m.role = 'owner')` → `and m.is_owner is true`; 2 chỗ `and m.status = 'active'` → `and m.is_active` (giữ `;`).

- [ ] **Step 9: `bootstrap_owner`** (`20260914001_…`): `  select m.role, m.status` → `  select m.role, iam._membership_status_code(m.is_active, m.removed_at)`; `  if v_role not in ('owner', 'store_owner') then` → `  if v_role <> 'store_owner' then`.

- [ ] **Step 10: `get_session_context`** (`20260914001_…`)
1. 2 chỗ `    select m.tenant_id, m.role, m.status, coalesce(m.is_owner, false)` → `    select m.tenant_id, m.role, iam._membership_status_code(m.is_active, m.removed_at), coalesce(m.is_owner, false)`
2. 2 chỗ `m.status = 'active'` → `m.is_active` (giữ `;`)
3. `    and v_role in ('owner', 'store_owner') then` → `    and v_role = 'store_owner' then`
4. `  if coalesce(v_is_owner, false) or v_role in ('owner', 'store_owner') then` → `  if coalesce(v_is_owner, false) or v_role = 'store_owner' then`

- [ ] **Step 11: Chạy test, xác nhận pass.**

- [ ] **Step 12: Dừng — tóm tắt.** Đề xuất commit: `refactor(iam): invitation and session rpcs use membership is_active`.

---

### Task 4: Đọc tenant / member (#17–24)

**Files:**
- Modify: test file + file owner #17–24

- [ ] **Step 1: Thêm test (fail)**

```dart
  group('tenant/member read rpcs (final definitions)', () {
    const owners = {
      'iam.activate_tenant': '20260916007_iam_patch_activate_tenant_default_store_scope.sql',
      'iam.update_tenant_profile': '20260826002_iam_tenant_audit_history_v2_payloads.sql',
      'iam.get_platform_tenant': '20260911003_iam_get_platform_tenant_owner_from_invitation.sql',
      'iam.search_platform_tenants': '20260811010_iam_platform_tenants_read.sql',
      'iam.list_accessible_tenants': '20260811014_iam_tenant_membership_lifecycle.sql',
      'iam.list_user_tenants': '20260811014_iam_tenant_membership_lifecycle.sql',
      'iam.list_platform_tenant_members': '20260811010_iam_platform_tenants_read.sql',
      'iam.list_tenant_members': '20260820004_iam_tenant_member_detail_user_info.sql',
    };

    test('rewritten per rules', () => _expectRewritten(owners));

    test('list_tenant_members filters and outputs derived status', () {
      final b = _lastFunctionBlock(_readMigration(owners['iam.list_tenant_members']!), 'iam.list_tenant_members');
      expect(b, contains('iam._membership_status_code(m.is_active, m.removed_at) as status,'));
      expect(b, contains('and (v_status is null or iam._membership_status_code(m.is_active, m.removed_at) = v_status)'));
    });
  });
```

- [ ] **Step 2: Chạy test, xác nhận fail.**

- [ ] **Step 3: Sửa theo bảng**

| Hàm (file owner) | Sửa |
|---|---|
| `activate_tenant` (`20260916007_…`) | 2 chỗ `m.status = 'active'` → `m.is_active`; 2 chỗ `(m.is_owner is true or m.role in ('owner', 'store_owner'))` → `(m.is_owner is true or m.role = 'store_owner')` |
| `update_tenant_profile` (`20260826002_…`) | `m.status = 'active'` → `m.is_active` |
| `get_platform_tenant` (`20260911003_…`) | 2 chỗ `coalesce(m.status, 'active') = 'active'` → `m.is_active` |
| `search_platform_tenants` (`20260811010_…`) | 2 chỗ `coalesce(om.status, 'active') = 'active'` → `om.is_active`; 1 chỗ `coalesce(m.status, 'active') = 'active'` → `m.is_active` |
| `list_accessible_tenants`, `list_user_tenants` (`20260811014_…`) | `m.status = 'active'` → `m.is_active` |
| `list_platform_tenant_members` (`20260811010_…`) | `coalesce(m.status, 'active') = 'active'` → `m.is_active` |

- [ ] **Step 4: `list_tenant_members`** (`20260820004_…`)
1. `      and m.status = 'active'` → `      and m.is_active`
2. `      m.status,` → `      iam._membership_status_code(m.is_active, m.removed_at) as status,`
3. `      and (v_status is null or m.status = v_status)` → `      and (v_status is null or iam._membership_status_code(m.is_active, m.removed_at) = v_status)`
4. `'is_owner', (f.is_owner is true or f.role = 'owner'),` → `'is_owner', (f.is_owner is true),`
5. Giữ kiểm tra `v_status not in ('active', 'inactive', 'removed')`.

- [ ] **Step 5: Chạy test, xác nhận pass.**

- [ ] **Step 6: Dừng — tóm tắt.** Đề xuất commit: `refactor(iam): tenant read rpcs use membership is_active`.

---

### Task 5: Đọc còn lại (#25–30)

**Files:**
- Modify: test file + file owner #25–30

- [ ] **Step 1: Thêm test (fail)**

```dart
  group('misc read rpcs (final definitions)', () {
    test('rewritten per rules', () => _expectRewritten(const {
          'iam.get_tenant_member': '20260820004_iam_tenant_member_detail_user_info.sql',
          'iam.get_tenant_invitation': '20260826001_iam_fix_utc_now_offset.sql',
          'iam.list_tenant_invitations': '20260826001_iam_fix_utc_now_offset.sql',
          'iam.list_assignable_invitation_roles': '20260811024_iam_patch_owner_role_canonicalization.sql',
          'iam.get_tenant_audit_log': '20260826004_iam_audit_logs_v2_rebuild.sql',
          'iam.search_tenant_audit_logs_v2': '20260826004_iam_audit_logs_v2_rebuild.sql',
        }));
  });
```

- [ ] **Step 2: Chạy test, xác nhận fail.**

- [ ] **Step 3: Sửa** — trong 6 hàm (file owner theo test), mỗi chỗ `m.status = 'active'` → `m.is_active`.

- [ ] **Step 4: Chạy test, xác nhận pass.**

- [ ] **Step 5: Dừng — tóm tắt.** Đề xuất commit: `refactor(iam): remaining read rpcs use membership is_active`.

---

### Task 6: Kiểm chứng toàn chuỗi

- [ ] **Step 1: Grep**

Run: `grep -nE "memberships.*\bstatus\b|\bm\.status\b|memberships_status_chk|memberships_tenant_user_active_uidx" supabase/migrations/*.sql`
Expected: chỉ còn trong thân hàm plpgsql **bản cũ** (không phải file owner) — đối chiếu từng kết quả với `REGISTRY.yaml`; không còn ở câu lệnh chạy trực tiếp.

- [ ] **Step 2: SQL contract test**

Run: `cd modules/iam/infrastructure && dart test test/iam_refactor_03_memberships_sql_contract_test.dart test/iam_refactor_01_tenants_sql_contract_test.dart test/iam_membership_owner_invariant_sql_contract_test.dart test/iam_tenant_invitation_create_sql_contract_test.dart test/iam_tenant_invitation_acceptance_sql_contract_test.dart test/iam_owner_role_canonicalization_sql_contract_test.dart test/iam_owner_activation_store_owner_role_sql_contract_test.dart test/iam_tenant_readiness_sql_contract_test.dart`
Expected: PASS; sửa assertion cũ nào kiểm tra `status`/`role = 'owner'` theo nội dung mới (trừ baseline fail sẵn).

- [ ] **Step 3: Policy**

Run: `dart run tools/vet45_supabase_migrate/bin/seed_registry.dart --write` rồi `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart --strict`
Expected: OK; `REGISTRY.yaml` có `_membership_status_code: 20260811014_iam_tenant_membership_lifecycle.sql`.

- [ ] **Step 4: Tiến độ spec** — dòng bảng 3 README: `… · 🧪 Đã sửa migration gốc, chờ reset`.

- [ ] **Step 5: Dừng — user reset + smoke test**

Sau `supabase db reset`:
```sql
select column_name from information_schema.columns
where table_schema = 'iam' and table_name = 'memberships' order by ordinal_position;
```
Expected: có `is_active`, `removed_at`; không có `status`. Smoke test (admin + ERP): đăng nhập owner/staff; lọc Đang hoạt động / Tạm ngưng / Đã loại; tạm ngưng → kích hoạt lại → gỡ staff; đổi role; chuyển quyền sở hữu (chỉ còn 1 owner); mời staff + accept; owner decline rồi reinvite; onboarding mới.
Đề xuất commit: `test(iam): verify memberships refactor against original migrations`.
