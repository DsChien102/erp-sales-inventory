import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String sql;

  setUpAll(() {
    final root = _findRepoRoot();
    sql = File(
      '${root.path}/supabase/migrations/_drafts/002_iam_fix_utc_now_offset.sql',
    ).readAsStringSync();
  });

  test('header declares the patch intent', () {
    expect(sql, contains('-- Title: IAM fix utc-now offset (store/compare with now())'));
    expect(sql, contains('-- Intent: iam_fix_utc_now_offset'));
  });

  test('never reintroduces the naive-timestamp expression', () {
    expect(sql, isNot(contains("timezone('utc', now())")));
  });

  test('uses now() as the timestamptz replacement throughout', () {
    expect(sql, contains('now()'));
  });

  group('table column defaults switched to now()', () {
    test('role_definitions created_at/updated_at', () {
      expect(
        sql,
        contains('alter table iam.role_definitions alter column created_at set default now();'),
      );
      expect(
        sql,
        contains('alter table iam.role_definitions alter column updated_at set default now();'),
      );
    });

    test('tenant_invitations status_changed_at/created_at/updated_at', () {
      expect(
        sql,
        contains(
          'alter table iam.tenant_invitations alter column status_changed_at set default now();',
        ),
      );
      expect(
        sql,
        contains('alter table iam.tenant_invitations alter column created_at set default now();'),
      );
      expect(
        sql,
        contains('alter table iam.tenant_invitations alter column updated_at set default now();'),
      );
    });
  });

  group('key functions redefined with the fix', () {
    for (final name in [
      'create_tenant_invitation',
      'list_tenant_invitations',
      'get_tenant_invitation',
      'begin_password_reset_operation',
      'resend_password_reset_operation',
      'begin_password_reset_operation_by_email',
      'resend_password_reset_operation_by_email',
      'resend_tenant_invitation',
      'revoke_tenant_invitation',
      'decline_invitation',
    ]) {
      test('iam.$name is redefined exactly once', () {
        final needle = 'create or replace function iam.$name(';
        expect(sql, contains(needle));
        expect(
          needle.allMatches(sql).length,
          equals(1),
          reason: 'iam.$name should be defined exactly once in the draft',
        );
      });
    }
  });

  group('excluded functions stay untouched by this draft', () {
    for (final name in [
      'create_tenant_onboarding',
      'accept_owner_activation',
      'search_platform_users',
      'get_platform_user',
    ]) {
      test('$name is not redefined here (owned by the sibling draft)', () {
        expect(sql, isNot(contains('create or replace function iam.$name(')));
      });
    }
  });

  test('does not recreate objects retired or owned by the final cleanup draft', () {
    for (final name in [
      'send_activation_invitation',
      'request_platform_password_reset',
      'inspect_owner_activation',
      'inspect_invitation_token',
      'accept_invitation',
    ]) {
      expect(sql, isNot(contains('create or replace function iam.$name(')));
    }
    expect(sql, isNot(contains('iam.owner_activations')));
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
