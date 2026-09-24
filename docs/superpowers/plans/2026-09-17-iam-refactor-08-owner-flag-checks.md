# IAM refactor — Bảng 8: kiểm tra quyền (chủ sở hữu + người dùng bị tạm ngừng) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** (1) 4 hàm IAM chỉ coi `is_owner = true` là chủ sở hữu; (2) sửa bug "Tạm ngừng người dùng" không có hiệu lực — người bị tạm ngừng mất quyền, bị chặn đăng nhập, tạm ngừng/khôi phục có audit kèm lý do. **Sửa trực tiếp migration gốc.**

**Architecture:** Task 1 sửa định nghĩa cuối của 4 hàm (owner). Task 2 thêm `iam._is_platform_user_suspended` + `iam.assert_my_platform_access` vào `20260911001`, đăng ký mã audit, sửa suspend/restore và 5 hàm kiểm tra quyền/context tại file owner. Task 3 Dart: mã lỗi, `LoginAuditAuthenticator`, thông báo đăng nhập admin + ERP. Không đổi bảng; không đổi chữ ký RPC có sẵn.

**Tech Stack:** PostgreSQL/Supabase plpgsql; Dart `package:test`; Flutter `flutter_test`.

**Spec:** [08-role-permissions.md](../specs/iam-schema-refactor/08-role-permissions.md) · [10-platform-admins.md §2](../specs/iam-schema-refactor/10-platform-admins.md) · Quy ước: [README §Quy ước implement](../specs/iam-schema-refactor/README.md#quy-ước-implement-sửa-trực-tiếp-migration-gốc)

## Global Constraints

- Tuân thủ **Quy ước implement**. Chạy sau plan [6](2026-09-17-iam-refactor-06-membership-store-scopes.md) (văn bản "trước" đã gồm thay đổi plan 1–6).
- Sau Task 1, trong 4 hàm owner không còn `'store_owner'` dùng làm điều kiện quyền.
- **Tạm ngừng người dùng (Task 2–3):**
  - Người bị tạm ngừng ⇔ `iam.platform_user_profiles.status = 'suspended'` (bảng giữ nguyên).
  - Mã lỗi `PLATFORM_USER_SUSPENDED`. Thông báo UI (admin + ERP): `Tài khoản của bạn đã bị tạm ngừng. Vui lòng liên hệ quản trị viên.`
  - Mã audit `iam.platform_user.suspended`, `iam.platform_user.restored` (nhóm `security`, scope `platform`, subject `account`); audit suspend lưu `reason`.
  - Admin không được tạm ngừng chính mình (`VALIDATION_ERROR`).
  - Context bị chặn: invalidation `identityInactive` + `blocked_error_code = PLATFORM_USER_SUSPENDED`.
  - Kiểm tra lúc đăng nhập chỉ chặn khi RPC trả `PLATFORM_USER_SUSPENDED`; lỗi khác không chặn đăng nhập.
  - Ban Supabase Auth / thu hồi phiên: ngoài phạm vi.
- Không promote, **không `git commit`** — cuối task tóm tắt + đề xuất commit rồi dừng.
- Trước khi sửa hàm/class: `node .gitnexus/run.cjs impact "<tên>" --direction upstream --repo .` (hàm SQL → `UNKNOWN`).

## Khảo sát — file owner

| Hàm | File owner | Task |
|---|---|---|
| `assign_member_role` | `20260820005_iam_assign_member_role_fix.sql` | 1 |
| `get_session_context`, `bootstrap_owner` | `20260914001_iam_get_session_context_multi_tenant.sql` | 1, 2 |
| `activate_tenant` | `20260916007_iam_patch_activate_tenant_default_store_scope.sql` | 1 |
| `_audit_event_category` | `20260826004_iam_audit_logs_v2_rebuild.sql` | 2 |
| `suspend_platform_user` | `20260820002_iam_platform_user_suspend_state_changed_fix.sql` | 2 |
| `restore_platform_user` | `20260811005_iam_platform_user_lifecycle.sql` | 2 |
| `has_permission`, `get_tenant_context`, `switch_tenant_context` | `20260811024_iam_patch_owner_role_canonicalization.sql` | 2 |
| `has_platform_permission` | `20260811003_iam_platform_admin_authz.sql` | 2 |
| **Mới** `_is_platform_user_suspended`, `assert_my_platform_access` | thêm cuối `20260911001_iam_patch_platform_user_status_enum.sql` (sau khi `status` đã là enum) | 2 |

## File Structure

| File | Trách nhiệm |
|---|---|
| Modify file owner (bảng Khảo sát) | Sửa tại chỗ |
| Create `modules/iam/infrastructure/test/iam_refactor_08_access_checks_sql_contract_test.dart` | SQL contract test |
| Modify `modules/iam/application/lib/src/shared/iam_blocked_codes.dart` | `platformUserSuspended` |
| Modify `modules/iam/infrastructure/lib/src/errors/iam_blocked_error_mapper.dart` | Map mã mới |
| Modify `modules/iam/infrastructure/lib/src/domain/auth/login_audit_authenticator.dart` + test | Kiểm tra tạm ngừng khi đăng nhập |
| Modify `apps/{erp,admin}/lib/features/iam/presentation/shared/iam_ui_failure_mapper.dart` + test | Thông báo |
| Modify `apps/admin/lib/features/auth/presentation/pages/login_page.dart` | Toast |
| Modify `docs/superpowers/specs/iam-schema-refactor/README.md` | Tiến độ |

Chạy test SQL: `cd modules/iam/infrastructure && dart test test/iam_refactor_08_access_checks_sql_contract_test.dart`

---

### Task 1: 4 hàm chỉ xét `is_owner`

**Files:**
- Create: test file
- Modify: `20260820005_…`, `20260914001_…`, `20260916007_…`

**Interfaces:**
- Produces: `assign_member_role(uuid, uuid, text)`, `get_session_context(uuid)`, `bootstrap_owner(uuid, text)`, `activate_tenant(uuid, int, text)` — chữ ký giữ nguyên. Test helper `_readMigration`, `_lastFunctionBlock`.

- [ ] **Step 1: Viết test (fail)**

```dart
import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — IAM refactor bảng 8 (owner flag) + suspended users
/// (docs/superpowers/specs/iam-schema-refactor/08-role-permissions.md, 10-platform-admins.md §2).
void main() {
  group('owner privileges depend only on is_owner', () {
    const owners = {
      'iam.assign_member_role': '20260820005_iam_assign_member_role_fix.sql',
      'iam.get_session_context': '20260914001_iam_get_session_context_multi_tenant.sql',
      'iam.bootstrap_owner': '20260914001_iam_get_session_context_multi_tenant.sql',
      'iam.activate_tenant': '20260916007_iam_patch_activate_tenant_default_store_scope.sql',
    };
    String body(String fn) => _lastFunctionBlock(_readMigration(owners[fn]!), fn);

    test('no store_owner role used as a privilege', () {
      for (final fn in owners.keys) {
        expect(body(fn), isNot(contains("role = 'store_owner'")), reason: fn);
        expect(body(fn), isNot(contains("role <> 'store_owner'")), reason: fn);
      }
    });

    test('assign_member_role requires owner caller and drops role-based last owner guard', () {
      final b = body('iam.assign_member_role');
      expect(b, contains('and m.is_owner is true'));
      expect(b, isNot(contains('LAST_OWNER_PROTECTED')));
      expect(b, isNot(contains('v_active_owner_count')));
    });

    test('session context and bootstrap use is_owner', () {
      expect(body('iam.get_session_context'), contains('and coalesce(v_is_owner, false) then'));
      expect(body('iam.get_session_context'), contains('  if coalesce(v_is_owner, false) then\n    v_permissions'));
      expect(body('iam.bootstrap_owner'), contains('if not coalesce(v_is_owner, false) then'));
    });

    test('activate_tenant locks owner rows by is_owner only', () {
      expect(body('iam.activate_tenant'), contains('    and m.is_owner is true\n    and m.is_active\n  for update;'));
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

- [ ] **Step 3: `assign_member_role`** (`20260820005_…`)
1. Khối kiểm tra caller: `        and (m.is_owner is true or m.role = 'store_owner')` → `        and m.is_owner is true`
2. Xoá toàn bộ khối:
```sql
  -- Protect the last owner from being demoted away from owner/store_owner
  if (v_target_row.is_owner is true or v_target_row.role = 'store_owner')
     and p_role <> 'store_owner' then
    select count(*)
    into v_active_owner_count
    from iam.memberships m
    where m.tenant_id = p_tenant_id
      and (m.is_owner is true or m.role = 'store_owner')
      and m.is_active;

    if v_active_owner_count <= 1 then
      raise exception 'LAST_OWNER_PROTECTED';
    end if;
  end if;
```
3. Xoá khai báo `  v_active_owner_count int := 0;`

- [ ] **Step 4: `get_session_context`** (`20260914001_…`)
1. `  if v_active_store_id is null\n    and v_role = 'store_owner' then` → `  if v_active_store_id is null\n    and coalesce(v_is_owner, false) then`
2. `  if coalesce(v_is_owner, false) or v_role = 'store_owner' then` → `  if coalesce(v_is_owner, false) then`

- [ ] **Step 5: `bootstrap_owner`** (`20260914001_…`)
1. `declare`: thêm `  v_is_owner boolean;`
2. Thay:
```sql
  select m.role, iam._membership_status_code(m.is_active, m.removed_at)
  into v_role, v_status
```
bằng:
```sql
  select m.role, iam._membership_status_code(m.is_active, m.removed_at), coalesce(m.is_owner, false)
  into v_role, v_status, v_is_owner
```
3. `  if v_role <> 'store_owner' then` → `  if not coalesce(v_is_owner, false) then`

- [ ] **Step 6: `activate_tenant`** (`20260916007_…`): trong khối `perform 1 from iam.memberships m … for update;`, `    and (m.is_owner is true or m.role = 'store_owner')` → `    and m.is_owner is true`.

- [ ] **Step 7: Chạy test, xác nhận pass.**

- [ ] **Step 8: Dừng — tóm tắt.** Smoke test sau reset: người có role "Chủ cửa hàng" nhưng không phải chủ không đổi được role người khác; owner đổi role chính mình vẫn là chủ. Đề xuất commit: `fix(iam): owner privileges depend only on is_owner`.

---

### Task 2: Chặn người dùng bị tạm ngừng (SQL)

**Files:**
- Modify: test file
- Modify: `20260911001_…`, `20260826004_…`, `20260820002_…`, `20260811005_…`, `20260811024_…`, `20260811003_…`, `20260914001_…`

**Interfaces:**
- Consumes: `iam.append_audit_log(p_scope, p_tenant_id, p_actor_user_id, p_event_code, p_subject_type, p_subject_id, p_result, p_source, p_tracking_id, p_before, p_after, …)`.
- Produces: `iam._is_platform_user_suspended(uuid) → boolean` (không grant client); `iam.assert_my_platform_access() → void` (grant `authenticated`, ném JSON `"code":"PLATFORM_USER_SUSPENDED"`).

- [ ] **Step 1: Thêm test (fail)**

```dart
  group('suspended platform users lose access', () {
    final statusEnum = _readMigration('20260911001_iam_patch_platform_user_status_enum.sql');

    test('private helper and access assert defined after status enum', () {
      expect(_lastFunctionBlock(statusEnum, 'iam._is_platform_user_suspended'), contains("p.status = 'suspended'"));
      expect(statusEnum, contains('revoke all on function iam._is_platform_user_suspended(uuid) from public, anon, authenticated;'));
      final assertFn = _lastFunctionBlock(statusEnum, 'iam.assert_my_platform_access');
      expect(assertFn, contains('"code":"PLATFORM_USER_SUSPENDED"'));
      expect(statusEnum, contains('grant execute on function iam.assert_my_platform_access() to authenticated;'));
    });

    test('audit events registered as security', () {
      final body = _lastFunctionBlock(_readMigration('20260826004_iam_audit_logs_v2_rebuild.sql'), 'iam._audit_event_category');
      expect(body, contains("'iam.platform_user.suspended',"));
      expect(body, contains("'iam.platform_user.restored' then return 'security';"));
    });

    test('suspend forbids self-suspension and audits reason; restore audits', () {
      final suspend = _lastFunctionBlock(
        _readMigration('20260820002_iam_platform_user_suspend_state_changed_fix.sql'),
        'iam.suspend_platform_user',
      );
      expect(suspend, contains('if p_user_id = auth.uid() then'));
      expect(suspend, contains("p_event_code => 'iam.platform_user.suspended'"));
      expect(suspend, contains("'reason', trim(p_reason)"));
      expect(
        _lastFunctionBlock(_readMigration('20260811005_iam_platform_user_lifecycle.sql'), 'iam.restore_platform_user'),
        contains("p_event_code => 'iam.platform_user.restored'"),
      );
    });

    test('permission and context checks deny suspended users', () {
      const guard = 'if iam._is_platform_user_suspended(v_user_id) then\n    return false;\n  end if;';
      final canon = _readMigration('20260811024_iam_patch_owner_role_canonicalization.sql');
      expect(_lastFunctionBlock(canon, 'iam.has_permission'), contains(guard));
      expect(
        _lastFunctionBlock(_readMigration('20260811003_iam_platform_admin_authz.sql'), 'iam.has_platform_permission'),
        contains(guard),
      );
      expect(
        _lastFunctionBlock(_readMigration('20260914001_iam_get_session_context_multi_tenant.sql'), 'iam.get_session_context'),
        contains('"code":"PLATFORM_USER_SUSPENDED"'),
      );
      expect(_lastFunctionBlock(canon, 'iam.switch_tenant_context'), contains("raise exception 'PLATFORM_USER_SUSPENDED';"));
      final ctx = _lastFunctionBlock(canon, 'iam.get_tenant_context');
      expect(ctx, contains("'invalidation_reason', 'identityInactive'"));
      expect(ctx, contains("'blocked_error_code', 'PLATFORM_USER_SUSPENDED'"));
    });
  });
```

- [ ] **Step 2: Chạy test, xác nhận fail.**

- [ ] **Step 3: `20260911001_iam_patch_platform_user_status_enum.sql`** — cuối file thêm:

```sql

create or replace function iam._is_platform_user_suspended(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = iam, pg_temp
as $$
  select exists (
    select 1
    from iam.platform_user_profiles p
    where p.user_id = p_user_id
      and p.status = 'suspended'
  );
$$;

revoke all on function iam._is_platform_user_suspended(uuid) from public, anon, authenticated;

create or replace function iam.assert_my_platform_access()
returns void
language plpgsql
stable
security definer
set search_path = iam, pg_temp
as $$
begin
  if auth.uid() is null then
    raise exception using errcode = 'P0001',
      message = '{"code":"NOT_AUTHENTICATED","message":"Not authenticated.","details":{}}';
  end if;

  if iam._is_platform_user_suspended(auth.uid()) then
    raise exception using errcode = 'P0001',
      message = '{"code":"PLATFORM_USER_SUSPENDED","message":"Platform user is suspended.","details":{}}';
  end if;
end;
$$;

revoke all on function iam.assert_my_platform_access() from public, anon;
grant execute on function iam.assert_my_platform_access() to authenticated;
```
Header `-- Touches:` thêm `, iam._is_platform_user_suspended, iam.assert_my_platform_access`.

- [ ] **Step 4: `_audit_event_category`** (`20260826004_…`) — thay:
```sql
    when 'iam.account.password_reset_completed',
         'iam.account.signed_out' then return 'security';
```
bằng:
```sql
    when 'iam.account.password_reset_completed',
         'iam.account.signed_out',
         'iam.platform_user.suspended',
         'iam.platform_user.restored' then return 'security';
```

- [ ] **Step 5: `suspend_platform_user`** (`20260820002_…`, định nghĩa cuối)
1. Ngay sau khối `if p_reason is null or trim(p_reason) = '' then raise exception 'VALIDATION_ERROR'; end if;` thêm:
```sql
  if p_user_id = auth.uid() then
    raise exception 'VALIDATION_ERROR';
  end if;
```
2. Ngay trước `end;` cuối hàm (sau câu ghi bảng chống lặp), thêm:
```sql

  perform iam.append_audit_log(
    p_scope => 'platform',
    p_tenant_id => null,
    p_actor_user_id => auth.uid(),
    p_event_code => 'iam.platform_user.suspended',
    p_subject_type => 'account',
    p_subject_id => p_user_id::text,
    p_result => 'success',
    p_source => 'admin',
    p_tracking_id => p_idempotency_key,
    p_before => jsonb_build_object('version', p_expected_version),
    p_after => jsonb_build_object(
      'status', 'suspended',
      'reason', trim(p_reason),
      'version', p_expected_version + 1
    )
  );
```

- [ ] **Step 6: `restore_platform_user`** (`20260811005_…`) — ngay sau khối `if not found then raise exception 'STATE_CHANGED'; end if;` thêm:
```sql

  perform iam.append_audit_log(
    p_scope => 'platform',
    p_tenant_id => null,
    p_actor_user_id => auth.uid(),
    p_event_code => 'iam.platform_user.restored',
    p_subject_type => 'account',
    p_subject_id => p_user_id::text,
    p_result => 'success',
    p_source => 'admin',
    p_tracking_id => coalesce(nullif(trim(p_idempotency_key), ''), gen_random_uuid()::text),
    p_before => jsonb_build_object('status', 'suspended', 'version', p_expected_version),
    p_after => jsonb_build_object('status', 'active', 'version', p_expected_version + 1)
  );
```

- [ ] **Step 7: `has_permission`** (`20260811024_…`) và **`has_platform_permission`** (`20260811003_…`) — trong cả hai, ngay sau khối `if v_user_id is null then return false; end if;` thêm:
```sql

  if iam._is_platform_user_suspended(v_user_id) then
    return false;
  end if;
```

- [ ] **Step 8: `get_session_context`** (`20260914001_…`) — ngay sau khối
```sql
  if v_user_id is null then
    raise exception using errcode = 'P0001',
      message = '{"code":"NOT_AUTHENTICATED","message":"Not authenticated.","details":{}}';
  end if;
```
thêm:
```sql

  if iam._is_platform_user_suspended(v_user_id) then
    raise exception using errcode = 'P0001',
      message = '{"code":"PLATFORM_USER_SUSPENDED","message":"Platform user is suspended.","details":{}}';
  end if;
```

- [ ] **Step 9: `get_tenant_context`** (`20260811024_…`) — ngay trước khối `if p_tenant_id is null then return jsonb_build_object('status', 'none'); end if;` thêm:
```sql
  if iam._is_platform_user_suspended(v_user_id) then
    return jsonb_build_object(
      'status', 'invalidated',
      'invalidation_reason', 'identityInactive',
      'blocked_error_code', 'PLATFORM_USER_SUSPENDED',
      'tenant_id', p_tenant_id
    );
  end if;

```

- [ ] **Step 10: `switch_tenant_context`** (`20260811024_…`) — ngay sau khối `if p_target_tenant_id is null then raise exception 'TENANT_ACCESS_DENIED'; end if;` thêm:
```sql

  if iam._is_platform_user_suspended(v_user_id) then
    raise exception 'PLATFORM_USER_SUSPENDED';
  end if;
```

- [ ] **Step 11: Chạy test + policy**

Run: `cd modules/iam/infrastructure && dart test test/iam_refactor_08_access_checks_sql_contract_test.dart`
Run: `dart run tools/vet45_supabase_migrate/bin/seed_registry.dart --write` rồi `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart --strict`
Expected: PASS / OK; `REGISTRY.yaml` có 2 hàm mới trỏ `20260911001_…`.

- [ ] **Step 12: Dừng — tóm tắt.** Đề xuất commit: `fix(iam): deny access to suspended platform users and audit suspension`.

---

### Task 3: Dart — chặn đăng nhập người bị tạm ngừng + thông báo

**Files:**
- Modify: `modules/iam/application/lib/src/shared/iam_blocked_codes.dart`
- Modify: `modules/iam/infrastructure/lib/src/errors/iam_blocked_error_mapper.dart`
- Modify: `modules/iam/infrastructure/lib/src/domain/auth/login_audit_authenticator.dart`
- Modify: `modules/iam/infrastructure/test/login_audit_authenticator_test.dart`
- Modify: `apps/erp/lib/features/iam/presentation/shared/iam_ui_failure_mapper.dart`, `apps/admin/lib/features/iam/presentation/shared/iam_ui_failure_mapper.dart`
- Modify: `apps/erp/test/features/iam/presentation_module/shared/iam_ui_failure_mapper_test.dart`, `apps/admin/test/features/iam/presentation_module/shared/iam_ui_failure_mapper_test.dart`
- Modify: `apps/admin/lib/features/auth/presentation/pages/login_page.dart`
- Modify: `docs/superpowers/specs/iam-schema-refactor/README.md`

**Interfaces:**
- Consumes: RPC `iam.assert_my_platform_access()` (Task 2).
- Produces: `IamBlockedCodes.platformUserSuspended = 'PLATFORM_USER_SUSPENDED'`; `LoginAuditAuthenticator.signIn` đăng xuất rồi ném `IamBlockedException(IamBlockedCodes.platformUserSuspended)` khi bị tạm ngừng.

- [ ] **Step 1: Test authenticator (fail)**

Trong `modules/iam/infrastructure/test/login_audit_authenticator_test.dart`:
1. Test `'records platform login after successful Supabase auth sign-in'`: thêm `..registerHandler('assert_my_platform_access', (_) async => null)`.
2. Thêm test:
```dart
  test('signs out and blocks suspended platform user', () async {
    final inner = _RecordingAuthenticator();
    final supabase = FakeIamRpcSupabase()
      ..registerHandler(
        'assert_my_platform_access',
        (_) async => throw Exception(
          '{"code":"PLATFORM_USER_SUSPENDED","message":"Platform user is suspended."}',
        ),
      )
      ..registerHandler('record_my_platform_login', (_) async => null);
    final authenticator = LoginAuditAuthenticator(
      inner: inner,
      rpcClient: _rpcClient(supabase),
    );

    await expectLater(
      () => authenticator.signIn(email: 'suspended@vet45.com', password: 'secret'),
      throwsA(
        isA<IamBlockedException>().having(
          (e) => e.code,
          'code',
          IamBlockedCodes.platformUserSuspended,
        ),
      ),
    );

    expect(inner.signedInEmail, isNull);
    expect(
      supabase.calls.map((c) => c.functionName),
      isNot(contains('record_my_platform_login')),
    );
  });
```

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `cd modules/iam/infrastructure && dart test test/login_audit_authenticator_test.dart`
Expected: FAIL biên dịch.

- [ ] **Step 3: Mã lỗi + mapper**

`iam_blocked_codes.dart`: thêm sau `static const platformPermissionDenied = 'PLATFORM_PERMISSION_DENIED';`:
```dart
  static const platformUserSuspended = 'PLATFORM_USER_SUSPENDED';
```
`iam_blocked_error_mapper.dart`: thêm `IamBlockedCodes.platformUserSuspended,` làm phần tử đầu tiên của danh sách trong `for (final code in [`.

- [ ] **Step 4: `LoginAuditAuthenticator.signIn`** — thay thân:
```dart
    await _inner.signIn(email: email, password: password);
    try {
      await _rpcClient.callScalar<Object?>('record_my_platform_login');
    } on RpcException {
      // Last-login capture must not block an otherwise valid auth session.
    }
```
bằng:
```dart
    await _inner.signIn(email: email, password: password);
    try {
      await _rpcClient.callScalar<Object?>('assert_my_platform_access');
    } on RpcException catch (error) {
      if (error.message.toUpperCase().contains(IamBlockedCodes.platformUserSuspended)) {
        await _inner.signOut();
        throw const IamBlockedException(IamBlockedCodes.platformUserSuspended);
      }
      // Other failures do not block sign-in; server RPCs still deny suspended users.
    }
    try {
      await _rpcClient.callScalar<Object?>('record_my_platform_login');
    } on RpcException {
      // Last-login capture must not block an otherwise valid auth session.
    }
```

- [ ] **Step 5: Chạy test authenticator, xác nhận pass.**

- [ ] **Step 6: Test UI failure mapper (fail) — ERP + admin**

Trong cả hai file test `iam_ui_failure_mapper_test.dart`, thêm vào `group('IamUiFailureMapper', …)` (hoặc `main()` nếu không có group):
```dart
    test('PLATFORM_USER_SUSPENDED shows suspended account message', () {
      final failure = IamUiFailureMapper.from(
        const IamBlockedException(IamBlockedCodes.platformUserSuspended),
      );
      expect(failure.code, IamBlockedCodes.platformUserSuspended);
      expect(
        failure.message,
        'Tài khoản của bạn đã bị tạm ngừng. Vui lòng liên hệ quản trị viên.',
      );
    });
```
Run: `cd apps/erp && flutter test test/features/iam/presentation_module/shared/iam_ui_failure_mapper_test.dart` và tương tự `apps/admin` → FAIL.

- [ ] **Step 7: Sửa `IamUiFailureMapper` — ERP + admin**

Trong cả hai file: `_knownCodes` thêm `IamBlockedCodes.platformUserSuspended,` sau `IamBlockedCodes.platformPermissionDenied,`; `_localizedMessages` thêm sau dòng `IamBlockedCodes.platformPermissionDenied: …,`:
```dart
    IamBlockedCodes.platformUserSuspended:
        'Tài khoản của bạn đã bị tạm ngừng. Vui lòng liên hệ quản trị viên.',
```
Run lại 2 lệnh Step 6 → PASS.

- [ ] **Step 8: Màn đăng nhập admin** (`apps/admin/lib/features/auth/presentation/pages/login_page.dart`) — thay:
```dart
      final isPlatformDenied = signInFailure.message.contains(
        IamBlockedCodes.platformPermissionDenied,
      );
      VToast.show(
        context,
        title: 'Đăng nhập thất bại',
        message: isPlatformDenied
            ? 'Tài khoản không có quyền Platform Admin'
            : signInFailure.message,
        type: VToastType.danger,
      );
```
bằng:
```dart
      final isPlatformDenied = signInFailure.message.contains(
        IamBlockedCodes.platformPermissionDenied,
      );
      final isSuspended = signInFailure.message.contains(
        IamBlockedCodes.platformUserSuspended,
      );
      VToast.show(
        context,
        title: 'Đăng nhập thất bại',
        message: isSuspended
            ? 'Tài khoản của bạn đã bị tạm ngừng. Vui lòng liên hệ quản trị viên.'
            : isPlatformDenied
            ? 'Tài khoản không có quyền Platform Admin'
            : signInFailure.message,
        type: VToastType.danger,
      );
```
(ERP dùng `IamUiFailureMapper` qua `LoginCubit` → đã có thông báo ở Step 7.)

- [ ] **Step 9: Chạy test liên quan**
- `cd modules/iam/infrastructure && dart test test/login_audit_authenticator_test.dart`
- `cd apps/admin && flutter test test/features/iam/presentation_module/shared`
- `cd apps/erp && flutter test test/features/iam/presentation_module/shared`

Expected: PASS.

- [ ] **Step 10: Tiến độ spec** — dòng bảng 8 README: `… · 🧪 Đã sửa migration gốc, chờ reset`.

- [ ] **Step 11: Dừng — user reset + build app + smoke test**

(Dùng tài khoản test, không dùng tài khoản admin đang đăng nhập.)
1. Admin tạm ngừng A (có lý do); thử tạm ngừng chính mình → báo lỗi dữ liệu không hợp lệ.
2. Đăng nhập ERP bằng A → toast "Tài khoản của bạn đã bị tạm ngừng…", không vào được; nếu A là admin → app admin cùng thông báo.
3. A đang mở ERP từ trước → thao tác bán hàng / đổi tổ chức bị từ chối.
4. Khôi phục A → dùng lại bình thường.
```sql
select event_code, actor_user_id, target_id, detail_items, occurred_at
from iam.audit_logs
where event_code in ('iam.platform_user.suspended', 'iam.platform_user.restored')
order by occurred_at desc limit 5;
```
Expected: có dòng tạm ngừng (kèm `reason`) và khôi phục.
Đề xuất commit: `fix(iam): block suspended platform users at sign-in`.
