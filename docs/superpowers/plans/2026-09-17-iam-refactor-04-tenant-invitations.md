# IAM refactor — Bảng 4 `iam.tenant_invitations` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Đổi `revoke_reason` → `status_reason`, thêm FK `invited_by_membership_id → memberships(id)`, cho phép mời lại người đã bị gỡ bằng cách dùng lại membership cũ — **sửa trực tiếp migration gốc**.

**Architecture:** Task 1 sửa DDL tại `20260811017` (FK) và `20260811018` (tên cột). Task 2 sửa định nghĩa cuối `revoke_tenant_invitation` và `create_tenant_invitation` (cùng file owner `20260916005`). Task 3 kiểm chứng. Không đổi chữ ký RPC, key JSON, payload audit; không đổi Dart.

**Tech Stack:** PostgreSQL/Supabase plpgsql; Dart `package:test`.

**Spec:** [04-tenant-invitations.md](../specs/iam-schema-refactor/04-tenant-invitations.md) · Quy ước: [README §Quy ước implement](../specs/iam-schema-refactor/README.md#quy-ước-implement-sửa-trực-tiếp-migration-gốc)

## Global Constraints

- Tuân thủ **Quy ước implement**. Chạy sau plan [3](2026-09-17-iam-refactor-03-memberships.md) (mô hình `is_active` + `removed_at`; `create_tenant_invitation` đã sửa ở plan 3).
- Payload audit thu hồi giữ key `'revoke_reason'`.
- Dùng lại membership đã gỡ: `is_active = true`, `removed_at = null`, `role = coalesce(v_role.code, 'staff')`, `is_owner = false`, `status_changed_at = v_now`, `version = version + 1`, `updated_at = v_now`.
- Không promote, **không `git commit`** — cuối task tóm tắt + đề xuất commit rồi dừng.
- Trước khi sửa hàm: `node .gitnexus/run.cjs impact "<tên>" --direction upstream --repo .` (hàm SQL → `UNKNOWN`).

## Khảo sát

| Đối tượng | File | Ghi chú |
|---|---|---|
| `create table iam.tenant_invitations` | `20260811017_iam_tenant_invitation_create.sql` | Thêm FK tại đây (`memberships.id` là PK từ `20260811014`, chạy trước) |
| `add column if not exists revoke_reason text` | `20260811018_iam_tenant_invitation_resend_revoke.sql` | Đổi tên cột tại câu tạo |
| Ghi `revoke_reason` | `revoke_tenant_invitation` — owner `20260916005_iam_patch_invitation_membership_store_scope.sql` | Không nơi nào khác đọc cột |
| Tạo membership khi mời | `create_tenant_invitation` — owner `20260916005_…` | |

## File Structure

| File | Thay đổi |
|---|---|
| Modify `supabase/migrations/20260811017_iam_tenant_invitation_create.sql` | FK |
| Modify `supabase/migrations/20260811018_iam_tenant_invitation_resend_revoke.sql` | Tên cột |
| Modify `supabase/migrations/20260916005_iam_patch_invitation_membership_store_scope.sql` | 2 hàm |
| Create `modules/iam/infrastructure/test/iam_refactor_04_tenant_invitations_sql_contract_test.dart` | SQL contract test |
| Modify `docs/superpowers/specs/iam-schema-refactor/README.md` | Tiến độ |

Chạy test: `cd modules/iam/infrastructure && dart test test/iam_refactor_04_tenant_invitations_sql_contract_test.dart`

---

### Task 1: DDL

**Files:**
- Create: test file
- Modify: `20260811017_iam_tenant_invitation_create.sql`, `20260811018_iam_tenant_invitation_resend_revoke.sql`

- [ ] **Step 1: Viết test (fail)**

```dart
import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — IAM refactor bảng 4 `iam.tenant_invitations`
/// (docs/superpowers/specs/iam-schema-refactor/04-tenant-invitations.md).
void main() {
  group('tenant_invitations DDL', () {
    test('invited_by_membership_id references memberships', () {
      final sql = _readMigration('20260811017_iam_tenant_invitation_create.sql');
      expect(
        sql,
        contains('invited_by_membership_id uuid references iam.memberships (id) on delete set null,'),
      );
    });

    test('status_reason replaces revoke_reason column', () {
      final sql = _readMigration('20260811018_iam_tenant_invitation_resend_revoke.sql');
      expect(sql, contains('add column if not exists status_reason text,'));
      expect(sql, isNot(contains('add column if not exists revoke_reason')));
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

- [ ] **Step 2: Chạy test, xác nhận fail.**

- [ ] **Step 3: `20260811017_…`** — trong `create table if not exists iam.tenant_invitations (`, thay `  invited_by_membership_id uuid not null,` bằng:
```sql
  invited_by_membership_id uuid references iam.memberships (id) on delete set null,
```
Bỏ `not null` tại đây là đúng trạng thái cuối: `20260826003` vốn chạy `alter column invited_by_membership_id drop not null` (câu đó vẫn giữ, thành no-op), và CHECK `tenant_invitations_owner_inviter_chk` bảo đảm lời mời không phải owner phải có người mời.

- [ ] **Step 4: `20260811018_…`** — trong `alter table iam.tenant_invitations add column …`: `  add column if not exists revoke_reason text,` → `  add column if not exists status_reason text,`

- [ ] **Step 5: Chạy test, xác nhận pass.**

- [ ] **Step 6: Dừng — tóm tắt.** Đề xuất commit: `refactor(iam): invitation status_reason column and inviter FK`.

---

### Task 2: `revoke_tenant_invitation` + `create_tenant_invitation` (file owner `20260916005`)

**Files:**
- Modify: test file
- Modify: `supabase/migrations/20260916005_iam_patch_invitation_membership_store_scope.sql`

- [ ] **Step 1: Thêm test (fail)**

```dart
  group('invitation rpcs (final definitions)', () {
    final sql = _readMigration('20260916005_iam_patch_invitation_membership_store_scope.sql');

    test('revoke writes status_reason and keeps audit payload key', () {
      final body = _lastFunctionBlock(sql, 'iam.revoke_tenant_invitation');
      expect(body, contains('status_reason = v_reason,'));
      expect(body, isNot(contains('revoke_reason = v_reason')));
      expect(body, contains("'revoke_reason', v_reason"));
    });

    test('create invitation reuses a removed membership before inserting', () {
      final body = _lastFunctionBlock(sql, 'iam.create_tenant_invitation');
      final lookup = body.indexOf('and m.removed_at is not null');
      final reuse = body.indexOf('set is_active = true,');
      final insert = body.indexOf('insert into iam.memberships');
      expect(lookup, isNonNegative);
      expect(reuse, greaterThan(lookup));
      expect(insert, greaterThan(reuse));
      expect(body, contains('removed_at = null,'));
    });
  });
```

- [ ] **Step 2: Chạy test, xác nhận fail.**

- [ ] **Step 3: `revoke_tenant_invitation`** — `    revoke_reason = v_reason,` → `    status_reason = v_reason,` (không sửa `'revoke_reason', v_reason` trong audit).

- [ ] **Step 4: `create_tenant_invitation`** — thay khối insert membership (đã bỏ `status` ở plan 3):

```sql
  insert into iam.memberships (
    tenant_id, user_id, role, is_owner, version, created_at, updated_at
  )
  values (
    p_tenant_id,
    v_invitee_user_id,
    coalesce(v_role.code, 'staff'),
    false,
    1,
    v_now,
    v_now
  )
  returning id into v_target_membership_id;
```
bằng:
```sql
  -- Re-invite of a previously removed member: reuse the row
  -- (memberships_tenant_user_unique allows one row per tenant/user).
  select m.id
  into v_target_membership_id
  from iam.memberships m
  where m.tenant_id = p_tenant_id
    and m.user_id = v_invitee_user_id
    and m.removed_at is not null
  for update;

  if found then
    update iam.memberships
    set is_active = true,
        removed_at = null,
        role = coalesce(v_role.code, 'staff'),
        is_owner = false,
        status_changed_at = v_now,
        version = version + 1,
        updated_at = v_now
    where id = v_target_membership_id;
  else
    insert into iam.memberships (
      tenant_id, user_id, role, is_owner, version, created_at, updated_at
    )
    values (
      p_tenant_id,
      v_invitee_user_id,
      coalesce(v_role.code, 'staff'),
      false,
      1,
      v_now,
      v_now
    )
    returning id into v_target_membership_id;
  end if;
```

- [ ] **Step 5: Chạy test, xác nhận pass.**

- [ ] **Step 6: Dừng — tóm tắt.** Đề xuất commit: `fix(iam): allow re-inviting removed members and store invitation status_reason`.

---

### Task 3: Kiểm chứng

- [ ] **Step 1: Grep** — `grep -nE "revoke_reason" supabase/migrations/*.sql`
Expected: chỉ còn key payload audit `'revoke_reason', v_reason` và thân hàm plpgsql bản cũ; không còn `add column … revoke_reason`.

- [ ] **Step 2: Test** — `cd modules/iam/infrastructure && dart test test/iam_refactor_04_tenant_invitations_sql_contract_test.dart test/iam_tenant_invitation_resend_revoke_sql_contract_test.dart test/iam_tenant_invitation_create_sql_contract_test.dart test/iam_refactor_03_memberships_sql_contract_test.dart` → PASS (sửa assertion cũ nếu kiểm tra `revoke_reason =`).

- [ ] **Step 3: Policy** — `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart --strict` → OK.

- [ ] **Step 4: Tiến độ spec** — dòng bảng 4 README: `… · 🧪 Đã sửa migration gốc, chờ reset`.

- [ ] **Step 5: Dừng — user reset + smoke test**

Sau `supabase db reset` (ERP, owner):
1. Mời staff A → accept → gỡ A.
2. Mời lại A với role khác → thành công.
```sql
select id, role, is_active, removed_at, version from iam.memberships
where tenant_id = '<tenant>' and user_id = '<user A>';
```
Expected: 1 dòng, `is_active = true`, `removed_at = null`, role mới.
3. Thu hồi lời mời có lý do → `status_reason` có giá trị; audit còn `revoke_reason`.

Đề xuất commit: `test(iam): verify invitations refactor against original migrations`.
