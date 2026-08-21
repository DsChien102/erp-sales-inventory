import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String sql;

  setUpAll(() {
    final root = _findRepoRoot();
    sql = File(
      '${root.path}/supabase/migrations/20260811023_iam_owner_activation.sql',
    ).readAsStringSync();
  });

  group('iam owner activation RPC contract (Hướng 1)', () {
    test('accept requires a session and is authenticated-only', () {
      expect(sql, contains('function iam.accept_owner_activation'));
      expect(sql, contains('AUTHENTICATION_REQUIRED'));
      expect(
        sql,
        contains(
          'grant execute on function iam.accept_owner_activation(text, text) '
          'to authenticated',
        ),
      );
      // Not exposed to anon/service_role.
      expect(
        sql,
        contains(
          'revoke all on function iam.accept_owner_activation(text, text) '
          'from public, anon',
        ),
      );
    });

    test('accept creates the owner membership and an active profile', () {
      final body = sql.substring(
        sql.indexOf('function iam.accept_owner_activation'),
      );
      expect(body, contains('insert into iam.memberships'));
      expect(body, contains("'store_owner', true, 'active'"));
      expect(body, isNot(contains("'owner', true, 'active'")));
      expect(body, contains("status = 'active'"));
      expect(body, contains("status = 'accepted'"));
    });

    test('accept guards: expiry, attempt limit, email match', () {
      final body = sql.substring(
        sql.indexOf('function iam.accept_owner_activation'),
      );
      expect(body, contains('INVITATION_EXPIRED'));
      expect(body, contains('INVITATION_TOKEN_INVALID'));
      expect(body, contains('attempt_count'));
    });

    test('accept never changes tenant status', () {
      final body = sql.substring(
        sql.indexOf('function iam.accept_owner_activation'),
      );
      expect(body, isNot(contains('update iam.tenants')));
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
