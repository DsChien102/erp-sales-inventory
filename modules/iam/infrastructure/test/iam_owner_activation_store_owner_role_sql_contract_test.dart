import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String activationSql;
  late String canonicalizationSql;
  late String lifecycleSql;

  setUpAll(() {
    final root = _findRepoRoot();
    activationSql = File(
      '${root.path}/supabase/migrations/20260811023_iam_owner_activation.sql',
    ).readAsStringSync();
    canonicalizationSql = File(
      '${root.path}/supabase/migrations/20260811024_iam_patch_owner_role_canonicalization.sql',
    ).readAsStringSync();
    lifecycleSql = File(
      '${root.path}/supabase/migrations/20260811014_iam_tenant_membership_lifecycle.sql',
    ).readAsStringSync();
  });

  group('owner activation membership role canonicalization', () {
    test('accept_owner_activation creates owner membership with store_owner role', () {
      final body = _functionBody(activationSql, 'accept_owner_activation');

      expect(body, contains('insert into iam.memberships'));
      expect(body, contains("'store_owner', true, 'active'"));
      expect(body, isNot(contains("'owner', true, 'active'")));
    });

    test('existing owner memberships are backfilled away from owner role', () {
      expect(canonicalizationSql, contains("where role = 'owner'"));
      expect(canonicalizationSql, contains("set role = 'store_owner'"));
    });

    test('list_accessible_tenants exposes ownership separate from role', () {
      expect(lifecycleSql, contains('drop function if exists iam.list_accessible_tenants()'));
      expect(lifecycleSql, contains('is_owner boolean'));
      expect(lifecycleSql, contains('m.is_owner'));
    });
  });
}

String _functionBody(String sql, String functionName) {
  final start = sql.indexOf('function iam.$functionName');
  if (start < 0) {
    throw StateError('Function $functionName not found');
  }
  final end = sql.indexOf(r'$$;', start);
  if (end < 0) {
    throw StateError('Function $functionName body terminator not found');
  }
  return sql.substring(start, end);
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
