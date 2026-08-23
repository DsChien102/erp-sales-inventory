import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String canonicalizationSql;
  late String lifecycleSql;

  setUpAll(() {
    final root = _findRepoRoot();
    canonicalizationSql = File(
      '${root.path}/supabase/migrations/20260811024_iam_patch_owner_role_canonicalization.sql',
    ).readAsStringSync();
    lifecycleSql = File(
      '${root.path}/supabase/migrations/20260811014_iam_tenant_membership_lifecycle.sql',
    ).readAsStringSync();
  });

  // NB: the "accept_owner_activation creates store_owner membership" test was
  // removed — owner activation is retired. The store_owner / is_owner owner
  // membership invariant is now locked by
  // iam_owner_activation_retirement_sql_contract_test.dart (onboarding path).
  group('owner role canonicalization', () {
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
