import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String readSql;
  late String lifecycleSql;
  late String readinessSql;

  setUpAll(() {
    final root = _findRepoRoot();
    readSql = File(
      '${root.path}/supabase/migrations/20260811004_iam_platform_users_read.sql',
    ).readAsStringSync();
    lifecycleSql = File(
      '${root.path}/supabase/migrations/20260811005_iam_platform_user_lifecycle.sql',
    ).readAsStringSync();
    readinessSql = File(
      '${root.path}/supabase/migrations/20260811016_iam_tenant_readiness_activate.sql',
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

  group('iam.search_platform_users json page', () {
    test('returns full_name in given-name then family-middle-name order', () {
      final fnBody = _functionBody(
        readSql,
        'iam.search_platform_users(\n  p_query text default null,\n'
        '  p_status text default null,\n  p_cursor text default null,',
      );
      expect(fnBody, contains('as full_name'));
      expect(
        fnBody,
        contains("trim(concat_ws(' ', p.given_name, p.family_middle_name))"),
      );
      expect(
        fnBody,
        isNot(
          contains("trim(concat_ws(' ', p.family_middle_name, p.given_name))"),
        ),
      );
      expect(
        fnBody,
        contains(
          "trim(concat_ws(' ', u.raw_user_meta_data->>'first_name', u.raw_user_meta_data->>'last_name'))",
        ),
      );
      expect(fnBody, contains("u.raw_user_meta_data->>'last_name'"));
      expect(fnBody, contains("u.raw_user_meta_data->>'first_name'"));
    });
  });

  group('platform user activation effective read model', () {
    test('defines Auth-derived effective status helper', () {
      expect(
        readSql,
        contains(
          'create or replace function iam._platform_user_effective_status(',
        ),
      );
      expect(readSql, contains('p_email_confirmed_at timestamptz'));
      expect(
        readSql,
        contains("when p_email_confirmed_at is not null then 'active'"),
      );
      expect(readSql, contains("else 'pending_activation'"));
    });

    test('Admin list/detail status ignore legacy profile status', () {
      final pageSearchBody = _functionBody(
        readSql,
        'iam.search_platform_users(\n  p_query text default null,\n'
        '  p_status text default null,\n  p_cursor text default null,',
      );
      final detailBody = _functionBody(readSql, 'iam.get_platform_user(');

      for (final body in [pageSearchBody, detailBody]) {
        expect(
          body,
          contains('iam._platform_user_effective_status(u.email_confirmed_at)'),
        );
        expect(body, isNot(contains('coalesce(p.status')));
      }
    });

    test('Admin detail emailVerified is Auth-derived only', () {
      final detailBody = _functionBody(readSql, 'iam.get_platform_user(');

      expect(
        detailBody,
        contains('(u.email_confirmed_at is not null) as email_verified'),
      );
      expect(detailBody, isNot(contains('p.email_verified')));
    });

    test('activation resend gates on Auth confirmation, not profile status', () {
      final legacyBody = _functionBody(
        lifecycleSql,
        'iam.send_activation_invitation(p_user_id uuid)',
      );
      final versionedBody = _functionBody(
        lifecycleSql,
        'iam.send_activation_invitation(\n  p_user_id uuid,',
      );

      for (final body in [legacyBody, versionedBody]) {
        expect(body, contains('auth.users u'));
        expect(
          body,
          contains('iam._platform_user_effective_status(u.email_confirmed_at)'),
        );
        expect(body, isNot(contains('select status into v_status')));
      }
    });

    test('tenant readiness uses Auth-derived platform user activation', () {
      final readinessBody = _functionBody(
        readinessSql,
        'iam.get_tenant_readiness(',
      );

      expect(
        readinessBody,
        contains('iam._platform_user_effective_status(u.email_confirmed_at)'),
      );
      expect(readinessBody, isNot(contains('select p.status')));
      expect(readinessBody, isNot(contains("coalesce(v_owner_profile_status, '')")));
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
