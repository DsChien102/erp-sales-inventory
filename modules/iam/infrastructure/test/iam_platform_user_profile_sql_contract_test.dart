import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String readSql;
  late String lifecycleSql;

  setUpAll(() {
    final root = _findRepoRoot();
    readSql = File(
      '${root.path}/supabase/migrations/_drafts/004_iam_platform_users_read.sql',
    ).readAsStringSync();
    lifecycleSql = File(
      '${root.path}/supabase/migrations/_drafts/005_iam_platform_user_lifecycle.sql',
    ).readAsStringSync();
  });

  group('iam.get_my_platform_user_profile', () {
    test('is self-only via auth.uid() and takes no user_id parameter', () {
      expect(
        readSql,
        contains('create or replace function iam.get_my_platform_user_profile()'),
      );
      expect(readSql, contains('v_user_id uuid := auth.uid()'));
      expect(
        readSql,
        isNot(contains('iam.get_my_platform_user_profile(p_user_id')),
      );
    });

    test('never reads or returns login email', () {
      final fnBody = _functionBody(readSql, 'iam.get_my_platform_user_profile()');
      expect(fnBody.toLowerCase(), isNot(contains('email')));
    });

    test('reads from iam.platform_user_profiles authority table', () {
      expect(readSql, contains('from iam.platform_user_profiles'));
    });

    test('returns the locked, stable response keys', () {
      for (final key in const [
        "'user_id'",
        "'given_name'",
        "'family_middle_name'",
        "'phone_number'",
        "'avatar_reference'",
        "'status'",
      ]) {
        expect(readSql, contains(key), reason: 'missing response key $key');
      }
    });

    test('grants execute to authenticated, revoked from public/anon', () {
      expect(
        readSql,
        contains(
          'revoke all on function iam.get_my_platform_user_profile() from public, anon',
        ),
      );
      expect(
        readSql,
        contains(
          'grant execute on function iam.get_my_platform_user_profile() to authenticated',
        ),
      );
    });
  });

  group('iam.update_my_platform_user_profile', () {
    test('resolves user from auth.uid() and never accepts email', () {
      expect(
        lifecycleSql,
        contains(
          'create or replace function iam.update_my_platform_user_profile(',
        ),
      );
      expect(lifecycleSql, contains('v_user_id uuid := auth.uid()'));
      final fnBody = _functionBody(
        lifecycleSql,
        'iam.update_my_platform_user_profile(',
      );
      expect(fnBody.toLowerCase(), isNot(contains('email')));
      expect(fnBody.toLowerCase(), isNot(contains('auth.users')));
      expect(lifecycleSql, contains('iam.platform_user_profiles'));
    });

    test('stores empty names as null', () {
      expect(
        lifecycleSql,
        contains("nullif(trim(coalesce(p_given_name, '')), '')"),
      );
      expect(
        lifecycleSql,
        contains("nullif(trim(coalesce(p_family_name, '')), '')"),
      );
    });

    test('grants execute to authenticated, revoked from public/anon', () {
      expect(
        lifecycleSql,
        contains(
          'revoke all on function iam.update_my_platform_user_profile(text, text, text, text) from public, anon',
        ),
      );
      expect(
        lifecycleSql,
        contains(
          'grant execute on function iam.update_my_platform_user_profile(text, text, text, text) to authenticated',
        ),
      );
    });
  });
}

String _functionBody(String sql, String signaturePrefix) {
  final start = sql.indexOf(signaturePrefix);
  expect(start, greaterThanOrEqualTo(0), reason: 'function $signaturePrefix not found');
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
