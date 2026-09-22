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
        contains(
          'invited_by_membership_id uuid references iam.memberships (id) on delete set null,',
        ),
      );
    });

    test('accepted_membership_id index allows re-invited members', () {
      final sql = _readMigration('20260811017_iam_tenant_invitation_create.sql');
      expect(sql, isNot(contains('tenant_invitations_accepted_membership_uidx')));
      expect(
        sql,
        contains(
          'create index if not exists tenant_invitations_accepted_membership_idx\n'
          '  on iam.tenant_invitations (accepted_membership_id)',
        ),
      );
    });

    test('status_reason replaces revoke_reason column', () {
      final sql =
          _readMigration('20260811018_iam_tenant_invitation_resend_revoke.sql');
      expect(sql, contains('add column if not exists status_reason text,'));
      expect(sql, isNot(contains('add column if not exists revoke_reason')));
    });
  });

  group('invitation rpcs (final definitions)', () {
    final sql = _readMigration(
      '20260916005_iam_patch_invitation_membership_store_scope.sql',
    );

    test('revoke writes status_reason and keeps audit payload key', () {
      final body = _lastFunctionBlock(sql, 'iam.revoke_tenant_invitation');
      expect(body, contains('status_reason = v_reason,'));
      expect(body, isNot(contains('revoke_reason = v_reason')));
      expect(body, contains("'revoke_reason', v_reason"));
    });

    test('create invitation does not pre-create membership', () {
      final body = _lastFunctionBlock(sql, 'iam.create_tenant_invitation');
      expect(body, contains('and m.removed_at is null'));
      expect(body, contains('if v_existing_membership.is_active then'));
      expect(body, isNot(contains('insert into iam.memberships')));
      expect(body, isNot(contains('target_membership_id,')));
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
