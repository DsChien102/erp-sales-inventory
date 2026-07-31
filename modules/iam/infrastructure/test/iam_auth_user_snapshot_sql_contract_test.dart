import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String sql;
  late String fnBody;

  setUpAll(() {
    final root = _findRepoRoot();
    sql = File(
      '${root.path}/supabase/migrations/_drafts/016_iam_tenant_readiness_activate.sql',
    ).readAsStringSync();
    final start = sql.indexOf('iam.get_auth_user_snapshot(p_user_id uuid)');
    final bodyStart = sql.indexOf(r'as $$', start);
    final bodyEnd = sql.indexOf(r'$$;', bodyStart);
    fnBody = sql.substring(bodyStart, bodyEnd);
  });

  test('exposes exactly the four locked response fields', () {
    for (final key in const [
      "'user_id'",
      "'account_status'",
      "'email_verified'",
      "'evaluated_at'",
    ]) {
      expect(fnBody, contains(key), reason: 'missing $key');
    }
  });

  test('never returns login email, credential or session data', () {
    final lower = fnBody.toLowerCase();
    // The response object never carries a login-email value/key.
    expect(lower, isNot(contains("'email',")));
    expect(lower, isNot(contains('encrypted_password')));
    expect(lower, isNot(contains('recovery')));
    expect(lower, isNot(contains('refresh_token')));
  });

  test('returns unavailable when user does not exist', () {
    expect(fnBody, contains("'account_status', 'unavailable'"));
  });

  test('uses a fixed search_path and security definer', () {
    expect(sql, contains('security definer'));
    expect(sql, contains('set search_path = iam, auth, pg_temp'));
  });

  test('execute revoked from public/anon/authenticated, granted to service_role', () {
    expect(
      sql,
      contains(
        'revoke all on function iam.get_auth_user_snapshot(uuid) from public, anon, authenticated',
      ),
    );
    expect(
      sql,
      contains(
        'grant execute on function iam.get_auth_user_snapshot(uuid) to service_role',
      ),
    );
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
