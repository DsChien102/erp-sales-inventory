import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String sql;
  late String hasPermissionBody;

  setUpAll(() {
    final root = _findRepoRoot();
    sql = File(
      '${root.path}/supabase/migrations/'
      '20260811024_iam_patch_owner_role_canonicalization.sql',
    ).readAsStringSync();
    hasPermissionBody = _functionBody(
      sql,
      'create or replace function iam.has_permission(',
    );
  });

  group('iam owner-role canonicalization SQL contract', () {
    test('declares all patched RPCs in Touches header', () {
      final touches = sql.split('\n').firstWhere((line) => line.startsWith('-- Touches:'));

      for (final rpc in const [
        'iam.has_permission',
        'iam.get_session_context',
        'iam.get_tenant_context',
        'iam.switch_tenant_context',
      ]) {
        expect(touches, contains(rpc), reason: 'missing Touches entry: $rpc');
      }
    });

    test('has_permission grants owner bypass from is_owner flag only', () {
      expect(hasPermissionBody, contains('m.is_owner'));
      expect(hasPermissionBody, contains('if coalesce(v_is_owner, false) then'));
      expect(hasPermissionBody, contains('return true;'));
      expect(hasPermissionBody, isNot(contains("v_role = 'owner'")));
    });

    test('has_permission denies non-active memberships', () {
      expect(
        hasPermissionBody,
        contains('iam._membership_status_code(m.is_active, m.removed_at)'),
      );
      expect(
        hasPermissionBody,
        contains("v_role is null or coalesce(v_status, 'active') <> 'active'"),
      );
      expect(hasPermissionBody, contains('return false;'));
    });

    test('has_permission keeps org-admin namespaces owner-only', () {
      expect(
        hasPermissionBody,
        contains("p_permission like 'tenant.%' or p_permission like 'iam.%'"),
      );
      expect(hasPermissionBody, contains('return false;'));
    });

    test('has_permission grants operational permissions to active members', () {
      expect(
        hasPermissionBody,
        contains(
          '-- Everything else (operational: partner.* / catalog.* / pricing.* / ...).',
        ),
      );
      expect(hasPermissionBody.trimRight(), endsWith('return true;\nend;'));
      expect(hasPermissionBody, isNot(contains('iam.role_permissions')));
    });

    test('session and tenant context payloads expose is_owner', () {
      expect(sql, contains("'is_owner', coalesce(v_is_owner, false)"));
      expect(sql, contains('jsonb_build_object('));
    });
  });
}

String _functionBody(String sql, String signature) {
  final start = sql.indexOf(signature);
  expect(start, greaterThanOrEqualTo(0), reason: 'missing $signature');
  final end = sql.indexOf('\nend;\n\$\$;', start);
  expect(end, greaterThan(start), reason: 'missing function end for $signature');
  return sql.substring(start, end + '\nend;'.length);
}

Directory _findRepoRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync() &&
        Directory('${dir.path}/supabase').existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('Could not find repo root from ${Directory.current.path}');
    }
    dir = parent;
  }
}
