import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String lifecycleSql;
  late String readinessSql;

  setUpAll(() {
    final root = _findRepoRoot();
    lifecycleSql = File(
      '${root.path}/supabase/migrations/'
      '20260811014_iam_tenant_membership_lifecycle.sql',
    ).readAsStringSync();
    readinessSql = File(
      '${root.path}/supabase/migrations/'
      '20260811016_iam_tenant_readiness_activate.sql',
    ).readAsStringSync();
  });

  test('legacy owner roles are backfilled after is_owner is added', () {
    expect(
      lifecycleSql,
      contains(
        'update iam.memberships\n'
        'set is_owner = true\n'
        "where role = 'owner'\n"
        '  and is_owner is not true;',
      ),
    );
  });

  test('owner checks accept explicit owner flag or legacy owner role', () {
    const predicate = "(m.is_owner is true or m.role = 'owner')";
    expect(lifecycleSql, contains(predicate));
    expect(readinessSql, contains(predicate));
    expect(
      lifecycleSql,
      isNot(contains("coalesce(m.is_owner, m.role = 'owner')")),
    );
    expect(
      readinessSql,
      isNot(contains("coalesce(m.is_owner, m.role = 'owner')")),
    );
  });

  test('member payload does not hide a legacy owner behind false default', () {
    expect(
      lifecycleSql,
      contains(
        "'is_owner', "
        "(f.is_owner is true or f.role = 'owner')",
      ),
    );
  });

  test('membership mutation locks tenant before target membership', () {
    final body = _functionBody(
      lifecycleSql,
      'create or replace function iam._mutate_membership_status(',
    );

    const tenantLock =
        'perform 1\n'
        '  from iam.tenants t\n'
        '  where t.id = p_tenant_id\n'
        '  for update;';
    const membershipLock =
        'select *\n'
        '  into v_row\n'
        '  from iam.memberships m\n'
        '  where m.id = p_membership_id\n'
        '    and m.tenant_id = p_tenant_id\n'
        '  for update;';
    const ownerCount =
        'select count(*)\n'
        '    into v_active_owner_count';

    final tenantLockAt = body.indexOf(tenantLock);
    final membershipLockAt = body.indexOf(membershipLock);
    final ownerCountAt = body.indexOf(ownerCount);

    expect(tenantLockAt, greaterThanOrEqualTo(0));
    expect(membershipLockAt, greaterThan(tenantLockAt));
    expect(ownerCountAt, greaterThan(membershipLockAt));
  });

  test('membership mutation acquires the tenant row exactly once', () {
    final body = _functionBody(
      lifecycleSql,
      'create or replace function iam._mutate_membership_status(',
    );

    final tenantLocks = RegExp(
      r'from iam\.tenants t\s+'
      r'where t\.id = p_tenant_id\s+'
      r'for update;',
      multiLine: true,
    ).allMatches(body);

    expect(tenantLocks, hasLength(1));
  });

  test('deactivate and remove both delegate to protected status mutation', () {
    expect(
      lifecycleSql,
      contains(
        'return iam._mutate_membership_status(\n'
        '    p_tenant_id,\n'
        '    p_membership_id,\n'
        '    p_expected_version,\n'
        "    'inactive'",
      ),
    );
    expect(
      lifecycleSql,
      contains(
        'return iam._mutate_membership_status(\n'
        '    p_tenant_id,\n'
        '    p_membership_id,\n'
        '    p_expected_version,\n'
        "    'removed'",
      ),
    );
  });
}

String _functionBody(String sql, String signature) {
  final start = sql.indexOf(signature);
  if (start < 0) {
    throw StateError('Missing SQL function: $signature');
  }
  final end = sql.indexOf('\nend;\n\$\$;', start);
  if (end < 0) {
    throw StateError('Missing SQL function terminator: $signature');
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
