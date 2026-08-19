import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String sql;

  setUpAll(() {
    final root = _findRepoRoot();
    sql = File(
      '${root.path}/supabase/migrations/_drafts/iam_tenant_onboarding_registered_address.sql',
    ).readAsStringSync();
  });

  test('tenant onboarding draft persists registered legal address', () {
    expect(sql, contains('-- Touches: iam.create_tenant_onboarding'));
    expect(
      sql,
      contains('create or replace function iam.create_tenant_onboarding('),
    );
    expect(sql, contains('p_org_registered_address_text text default null'));
    expect(sql, contains('registered_address_text,'));
    expect(sql, contains('v_org_registered_address_text,'));
  });
}

Directory _findRepoRoot() {
  var current = Directory.current;
  while (true) {
    if (File('${current.path}/pubspec.yaml').existsSync() &&
        Directory('${current.path}/supabase/migrations').existsSync()) {
      return current;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not find repo root from ${Directory.current.path}');
    }
    current = parent;
  }
}
