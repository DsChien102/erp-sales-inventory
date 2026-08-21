import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String sql;

  setUpAll(() {
    final root = _findRepoRoot();
    sql = File(
      '${root.path}/supabase/migrations/_drafts/001_iam_pending_platform_profile_onboarding.sql',
    ).readAsStringSync();
  });

  group('schema: relax FK + new columns', () {
    test('header touches the four RPCs and two tables', () {
      expect(
        sql,
        contains(
          '-- Touches: iam.platform_user_profiles, iam.owner_activations, '
          'iam.create_tenant_onboarding, iam.accept_owner_activation, '
          'iam.search_platform_users, iam.get_platform_user',
        ),
      );
    });

    test('drops the auth.users FK on platform_user_profiles.user_id', () {
      expect(
        sql,
        contains(
          'drop constraint if exists platform_user_profiles_user_id_fkey',
        ),
      );
    });

    test('adds email column to platform_user_profiles', () {
      expect(sql, contains('add column if not exists email text'));
    });

    test('adds provisioned_user_id to owner_activations', () {
      expect(
        sql,
        contains('add column if not exists provisioned_user_id uuid'),
      );
    });
  });

  group('onboarding: create pending profile for new owner', () {
    String onboardingFn() {
      final start = sql.indexOf(
        'create or replace function iam.create_tenant_onboarding(',
      );
      expect(start, isNonNegative, reason: 'onboarding fn present');
      return sql.substring(start);
    }

    test('declares the provisioned user id variable', () {
      expect(onboardingFn(), contains('v_provisioned_user_id uuid'));
    });

    test('resolves an existing auth user by canonical email', () {
      expect(onboardingFn(), contains('where lower(u.email::text) = v_owner_email'));
    });

    test('resolves an existing pending profile by email (idempotent retry)', () {
      expect(onboardingFn(), contains('where lower(p.email) = v_owner_email'));
    });

    test('materialises a pending_activation profile with a generated id', () {
      final fn = onboardingFn();
      expect(fn, contains('v_provisioned_user_id := gen_random_uuid()'));
      expect(fn, contains('insert into iam.platform_user_profiles ('));
      expect(fn, contains("'pending_activation'"));
    });

    test('stores provisioned_user_id on the owner activation row', () {
      final fn = onboardingFn();
      expect(fn, contains('provisioned_user_id'));
      expect(fn, contains('coalesce(v_provisioned_user_id, p_owner_user_id)'));
    });

    test('never persists raw credentials', () {
      final fn = onboardingFn();
      expect(fn, isNot(contains('encrypted_password')));
      expect(fn, isNot(contains('raw_activation_token')));
    });
  });

  group('activation: reconcile placeholder onto real auth id', () {
    String acceptFn() {
      final start = sql.indexOf(
        'create or replace function iam.accept_owner_activation(',
      );
      expect(start, isNonNegative, reason: 'accept fn present');
      return sql.substring(start);
    }

    test('branches on provisioned id differing from the caller', () {
      final fn = acceptFn();
      expect(fn, contains('v_row.provisioned_user_id is not null'));
      expect(fn, contains('v_row.provisioned_user_id <> v_caller'));
    });

    test('copies placeholder data onto the real auth profile as active', () {
      final fn = acceptFn();
      expect(fn, contains('insert into iam.platform_user_profiles ('));
      expect(fn, contains('from iam.platform_user_profiles ph'));
      expect(fn, contains('where ph.user_id = v_row.provisioned_user_id'));
      expect(fn, contains("'active'"));
    });

    test('deletes the placeholder profile after reconciling', () {
      final fn = acceptFn();
      expect(fn, contains('delete from iam.platform_user_profiles'));
      expect(fn, contains('where user_id = v_row.provisioned_user_id'));
    });

    test('activation is never lost: minimal fallback present in both branches', () {
      final fn = acceptFn();
      final minimal = 'insert into iam.platform_user_profiles (user_id, status)';
      expect(
        minimal.allMatches(fn).length,
        greaterThanOrEqualTo(2),
        reason: 'reconcile and else branches each ensure an active profile',
      );
    });

    test('still creates the owner membership (is_owner store_owner)', () {
      final fn = acceptFn();
      expect(
        fn,
        contains(
          'insert into iam.memberships (tenant_id, user_id, role, is_owner, status)',
        ),
      );
      expect(fn, contains("'store_owner', true, 'active'"));
    });
  });

  group('reads: pending users appear in list and detail', () {
    String searchFn() {
      final start = sql.indexOf(
        'create or replace function iam.search_platform_users(',
      );
      expect(start, isNonNegative, reason: 'search fn present');
      final next = sql.indexOf('create or replace function iam.get_platform_user(');
      return next > start ? sql.substring(start, next) : sql.substring(start);
    }

    String getFn() {
      final start = sql.indexOf(
        'create or replace function iam.get_platform_user(',
      );
      expect(start, isNonNegative, reason: 'get fn present');
      return sql.substring(start);
    }

    test('search sources from profiles full-outer-joined to auth', () {
      final fn = searchFn();
      expect(fn, contains('from iam.platform_user_profiles p'));
      expect(fn, contains('full outer join auth.users u on u.id = p.user_id'));
      expect(fn, contains('coalesce(u.email, p.email)'));
      expect(fn, contains("coalesce(p.status, 'pending_activation')"));
    });

    test('get resolves by either the auth id or the profile id', () {
      final fn = getFn();
      expect(fn, contains('from iam.platform_user_profiles p'));
      expect(fn, contains('full outer join auth.users u on u.id = p.user_id'));
      expect(fn, contains('where coalesce(u.id, p.user_id) = p_user_id'));
      expect(fn, contains('coalesce(u.email::text, p.email'));
    });
  });

  group('hardening: pending-email uniqueness + orphan cleanup', () {
    test('enforces one pending placeholder per email via partial unique index', () {
      expect(
        sql,
        contains(
          'create unique index if not exists platform_user_profiles_pending_email_uidx',
        ),
      );
      expect(sql, contains('on iam.platform_user_profiles (lower(email))'));
      expect(sql, contains("where status = 'pending_activation'"));
    });

    test('accept deletes leftover pending placeholders for the same email', () {
      final start = sql.indexOf(
        'create or replace function iam.accept_owner_activation(',
      );
      expect(start, isNonNegative, reason: 'accept fn present');
      final fn = sql.substring(start);
      expect(fn, contains('delete from iam.platform_user_profiles'));
      expect(fn, contains("where status = 'pending_activation'"));
      expect(fn, contains('lower(email) = lower(v_row.invitee_email)'));
      expect(fn, contains('and user_id <> v_caller'));
    });

    test('search hides an orphan pending placeholder once its email has auth', () {
      final start = sql.indexOf(
        'create or replace function iam.search_platform_users(',
      );
      expect(start, isNonNegative, reason: 'search fn present');
      final fn = sql.substring(start);
      expect(fn, contains('and not ('));
      expect(fn, contains('u.id is null'));
      expect(fn, contains("and p.status = 'pending_activation'"));
      expect(fn, contains('where lower(au.email::text) = lower(p.email)'));
    });

    test('auth.users trigger cleans pending placeholders path-independently', () {
      expect(
        sql,
        contains(
          'create or replace function iam._cleanup_pending_profile_on_auth_user()',
        ),
      );
      expect(sql, contains('after insert on auth.users'));
      expect(sql, contains('execute function iam._cleanup_pending_profile_on_auth_user()'));
      final start = sql.indexOf(
        'create or replace function iam._cleanup_pending_profile_on_auth_user()',
      );
      final fn = sql.substring(start);
      expect(fn, contains("where p.status = 'pending_activation'"));
      expect(fn, contains('lower(p.email) = lower(new.email::text)'));
      expect(fn, contains('and p.user_id <> new.id'));
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
