import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String sql;

  setUpAll(() {
    final root = _findRepoRoot();
    final file = File(
      '${root.path}/supabase/migrations/_drafts/iam_platform_user_suspend_state_changed_fix.sql',
    );
    expect(file.existsSync(), isTrue, reason: 'hotfix draft must exist');
    sql = file.readAsStringSync();
  });

  test('get_platform_user detail returns optimistic concurrency version', () {
    final body = _functionBody(sql, 'iam.get_platform_user(');

    expect(body, contains('coalesce(p.version, 1) as version'));
    expect(body, contains("'version', v_row.version"));
  });

  test('get_platform_user returns suspended profile status after suspend', () {
    final body = _functionBody(sql, 'iam.get_platform_user(');

    expect(
      body,
      contains("case when p.status = 'suspended' then 'suspended'"),
    );
    expect(
      body,
      isNot(
        contains(
          'iam._platform_user_effective_status(u.email_confirmed_at)::text as status',
        ),
      ),
    );
  });

  test('search_platform_users returns and filters suspended profile status', () {
    final body = _functionBody(sql, 'iam.search_platform_users(');

    expect(
      body,
      contains("case when p.status = 'suspended' then 'suspended'"),
    );
    expect(body, contains('end = p_status'));
  });

  test('suspend_platform_user treats missing profile row as version 1', () {
    final body = _functionBody(
      sql,
      'iam.suspend_platform_user(\n  p_user_id uuid,',
    );

    expect(body, contains('if not found then'));
    expect(body, contains('v_version := 1;'));
    expect(body, contains('if v_version is distinct from p_expected_version then'));
  });
}

String _functionBody(String sql, String signaturePrefix) {
  final start = sql.indexOf(signaturePrefix);
  expect(
    start,
    greaterThanOrEqualTo(0),
    reason: 'function $signaturePrefix not found',
  );
  final bodyStart = sql.indexOf(r'as $$', start);
  final bodyEnd = sql.indexOf(r'$$;', bodyStart);
  expect(bodyStart, greaterThanOrEqualTo(0));
  expect(bodyEnd, greaterThan(bodyStart));
  return sql.substring(bodyStart, bodyEnd);
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
