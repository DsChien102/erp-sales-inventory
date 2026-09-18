import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — IAM refactor bảng 8 (owner flag) + suspended users
/// (docs/superpowers/specs/iam-schema-refactor/08-role-permissions.md,
/// 10-platform-admins.md §2).
void main() {
  group('owner privileges depend only on is_owner', () {
    const owners = {
      'iam.assign_member_role': '20260820005_iam_assign_member_role_fix.sql',
      'iam.get_session_context':
          '20260914001_iam_get_session_context_multi_tenant.sql',
      'iam.bootstrap_owner':
          '20260914001_iam_get_session_context_multi_tenant.sql',
      'iam.activate_tenant':
          '20260916007_iam_patch_activate_tenant_default_store_scope.sql',
    };
    String body(String fn) => _lastFunctionBlock(_readMigration(owners[fn]!), fn);

    test('no store_owner role used as a privilege', () {
      for (final fn in owners.keys) {
        expect(body(fn), isNot(contains("role = 'store_owner'")), reason: fn);
        expect(body(fn), isNot(contains("role <> 'store_owner'")), reason: fn);
      }
    });

    test('assign_member_role requires owner caller and drops role-based last owner guard',
        () {
      final b = body('iam.assign_member_role');
      expect(b, contains('and m.is_owner is true'));
      expect(b, isNot(contains('LAST_OWNER_PROTECTED')));
      expect(b, isNot(contains('v_active_owner_count')));
    });

    test('session context and bootstrap use is_owner', () {
      expect(
        body('iam.get_session_context'),
        contains('and coalesce(v_is_owner, false) then'),
      );
      expect(
        body('iam.get_session_context'),
        contains('  if coalesce(v_is_owner, false) then\n    v_permissions'),
      );
      expect(
        body('iam.bootstrap_owner'),
        contains('if not coalesce(v_is_owner, false) then'),
      );
    });

    test('activate_tenant locks owner rows by is_owner only', () {
      expect(
        body('iam.activate_tenant'),
        contains(
          '    and m.is_owner is true\n    and m.is_active\n  for update;',
        ),
      );
    });
  });

  group('suspended platform users lose access', () {
    final statusEnum =
        _readMigration('20260911001_iam_patch_platform_user_status_enum.sql');

    test('private helper and access assert defined after status enum', () {
      expect(
        _lastFunctionBlock(statusEnum, 'iam._is_platform_user_suspended'),
        contains("p.status = 'suspended'"),
      );
      expect(
        statusEnum,
        contains(
          'revoke all on function iam._is_platform_user_suspended(uuid) from public, anon, authenticated;',
        ),
      );
      final assertFn =
          _lastFunctionBlock(statusEnum, 'iam.assert_my_platform_access');
      expect(assertFn, contains('"code":"PLATFORM_USER_SUSPENDED"'));
      expect(
        statusEnum,
        contains(
          'grant execute on function iam.assert_my_platform_access() to authenticated;',
        ),
      );
    });

    test('audit events registered as security', () {
      final body = _lastFunctionBlock(
        _readMigration('20260826004_iam_audit_logs_v2_rebuild.sql'),
        'iam._audit_event_category',
      );
      expect(body, contains("'iam.platform_user.suspended',"));
      expect(
        body,
        contains("'iam.platform_user.restored' then return 'security';"),
      );
    });

    test('suspend forbids self-suspension and audits reason; restore audits',
        () {
      final suspend = _lastFunctionBlock(
        _readMigration(
          '20260820002_iam_platform_user_suspend_state_changed_fix.sql',
        ),
        'iam.suspend_platform_user',
      );
      expect(suspend, contains('if p_user_id = auth.uid() then'));
      expect(suspend, contains("p_event_code => 'iam.platform_user.suspended'"));
      expect(suspend, contains("'reason', trim(p_reason)"));
      expect(
        _lastFunctionBlock(
          _readMigration('20260811005_iam_platform_user_lifecycle.sql'),
          'iam.restore_platform_user',
        ),
        contains("p_event_code => 'iam.platform_user.restored'"),
      );
    });

    test('permission and context checks deny suspended users', () {
      const guard =
          'if iam._is_platform_user_suspended(v_user_id) then\n    return false;\n  end if;';
      final canon =
          _readMigration('20260811024_iam_patch_owner_role_canonicalization.sql');
      expect(_lastFunctionBlock(canon, 'iam.has_permission'), contains(guard));
      expect(
        _lastFunctionBlock(
          _readMigration('20260811003_iam_platform_admin_authz.sql'),
          'iam.has_platform_permission',
        ),
        contains(guard),
      );
      expect(
        _lastFunctionBlock(
          _readMigration('20260914001_iam_get_session_context_multi_tenant.sql'),
          'iam.get_session_context',
        ),
        contains('"code":"PLATFORM_USER_SUSPENDED"'),
      );
      expect(
        _lastFunctionBlock(canon, 'iam.switch_tenant_context'),
        contains("raise exception 'PLATFORM_USER_SUSPENDED';"),
      );
      final ctx = _lastFunctionBlock(canon, 'iam.get_tenant_context');
      expect(ctx, contains("'invalidation_reason', 'identityInactive'"));
      expect(ctx, contains("'blocked_error_code', 'PLATFORM_USER_SUSPENDED'"));
    });
  });
}

String _readMigration(String fileName) {
  final root = _findRepoRoot();
  return File('${root.path}/supabase/migrations/$fileName').readAsStringSync();
}

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
