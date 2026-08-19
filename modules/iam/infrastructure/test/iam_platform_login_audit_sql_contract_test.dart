import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String sql;

  setUpAll(() {
    final root = _findRepoRoot();
    final file = File(
      '${root.path}/supabase/migrations/_drafts/iam_platform_login_audit.sql',
    );
    expect(file.existsSync(), isTrue, reason: 'login audit draft must exist');
    sql = file.readAsStringSync();
  });

  test('record_my_platform_login resolves current auth user only', () {
    final body = _functionBody(sql, 'iam.record_my_platform_login()');

    expect(body, contains('v_user_id uuid := auth.uid()'));
    expect(body, isNot(contains('p_user_id')));
  });

  test('record_my_platform_login updates last_login_at', () {
    final body = _functionBody(sql, 'iam.record_my_platform_login()');

    expect(body, contains('last_login_at'));
    expect(body, contains('last_login_at = now()'));
    expect(body, contains('updated_at = now()'));
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
