import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String sql;

  setUpAll(() {
    final root = _findRepoRoot();
    sql = File(
      '${root.path}/supabase/migrations/20260811006_iam_create_tenant_onboarding.sql',
    ).readAsStringSync();
  });

  group('iam onboarding new owner SQL contract', () {
    test('defines resolve-or-create Platform User RPC for onboarding', () {
      expect(
        sql,
        contains(
          'create or replace function iam.resolve_or_create_platform_user_for_onboarding(',
        ),
      );
      expect(
        sql,
        contains(
          'Touches: iam.create_tenant_onboarding, iam.get_tenant_onboarding_operation, iam.retry_tenant_onboarding_operation, iam.resolve_or_create_platform_user_for_onboarding, iam.platform_identity_create_pending_user_for_onboarding',
        ),
      );
      for (final param in const [
        'p_email text',
        'p_first_name text',
        'p_last_name text',
        'p_phone text',
        'p_idempotency_key text',
        'p_correlation_id text',
      ]) {
        expect(sql, contains(param), reason: param);
      }
    });

    test('resolves existing Auth user by canonical email', () {
      expect(sql, contains('lower(trim(p_email))'));
      expect(sql, contains('from auth.users'));
      expect(sql, contains('where lower(u.email::text) = v_email'));
      expect(sql, contains("'is_new_user', false"));
    });

    test('provisions pending activation profile without owning credentials', () {
      expect(sql, contains("status, email_verified"));
      expect(sql, contains("'pending_activation'"));
      expect(sql, contains("'is_new_user', true"));
      expect(sql, isNot(contains('password')));
      expect(sql, isNot(contains('raw_activation_token')));
      expect(sql, isNot(contains('activation_token text')));
    });

    test('defines Platform Identity pending-user helper used by onboarding', () {
      expect(
        sql,
        contains(
          'create or replace function iam.platform_identity_create_pending_user_for_onboarding(',
        ),
      );
      for (final param in const [
        'p_email text',
        'p_given_name text',
        'p_family_middle_name text',
        'p_phone_number text',
        'p_idempotency_key text',
        'p_correlation_id text',
      ]) {
        expect(sql, contains(param), reason: param);
      }
      expect(
        sql,
        contains('iam.platform_identity_create_pending_user_for_onboarding('),
      );
    });

    test('Platform Identity helper creates Auth user without raw credentials', () {
      expect(sql, contains('insert into auth.users'));
      expect(sql, contains('raw_user_meta_data'));
      expect(sql, contains("'pending_activation', true"));
      expect(sql, isNot(contains('encrypted_password')));
      expect(sql, isNot(contains('raw_activation_token')));
      expect(sql, isNot(contains('activation_token text')));
    });

    test('enqueues activation invitation without exposing a raw token', () {
      expect(sql, contains("iam.enqueue_outbox_message("));
      expect(sql, contains("'template_id', 'activation_invitation'"));
      expect(sql, contains("'event_version', 1"));
      expect(sql, contains("'outcome_id'"));
      expect(sql, isNot(contains('platform_activation_invitation')));
      expect(sql, isNot(contains("'activation_token'")));
    });

    test('enqueues new-owner activation invitation after tenant id exists', () {
      final resolveStart = sql.indexOf(
        'create or replace function iam.resolve_or_create_platform_user_for_onboarding(',
      );
      final onboardingStart = sql.indexOf(
        'create or replace function iam.create_tenant_onboarding(',
      );
      expect(resolveStart, isNonNegative);
      expect(onboardingStart, isNonNegative);

      final resolveFunction = sql.substring(resolveStart, onboardingStart);
      final onboardingFunction = sql.substring(onboardingStart);

      expect(resolveFunction, isNot(contains('iam.enqueue_outbox_message(')));
      // Hướng 1 (unified): existing-owner email resolved from Auth; new-owner from
      // params. Both paths enqueue the invitation email after the tenant exists.
      expect(onboardingFunction, contains('if not v_is_new then'));
      expect(onboardingFunction, contains('perform iam.enqueue_outbox_message('));
      expect(onboardingFunction, contains('v_tenant_id,'));
      expect(onboardingFunction, contains("'tenant_id', v_tenant_id"));
      expect(onboardingFunction, contains("'to_email', v_owner_email"));
    });

    test('keeps tenant onboarding RPC owner-user-id based', () {
      expect(
        sql,
        contains('create or replace function iam.create_tenant_onboarding('),
      );
      expect(sql, contains('p_owner_user_id uuid'));
      expect(sql, contains('p_is_new_user boolean'));
    });

    test('persists organization profile and legal fields during onboarding', () {
      final onboardingFunction = sql.substring(
        sql.indexOf('create or replace function iam.create_tenant_onboarding('),
      );
      for (final param in const [
        'p_org_display_name text',
        'p_org_contact_email text',
        'p_org_contact_phone text',
        'p_org_contact_address_text text',
        'p_org_province_code text',
        'p_org_commune_code text',
        'p_org_legal_name text',
        'p_org_tax_code text',
      ]) {
        expect(onboardingFunction, contains(param), reason: param);
      }

      expect(onboardingFunction, contains('insert into iam.tenants ('));
      expect(onboardingFunction, contains('display_name,'));
      expect(onboardingFunction, contains('contact_email,'));
      expect(onboardingFunction, contains('contact_phone,'));
      expect(onboardingFunction, contains('contact_address_text,'));
      expect(onboardingFunction, contains('province_code,'));
      expect(onboardingFunction, contains('commune_code,'));
      expect(onboardingFunction, contains('insert into iam.tenant_legal_profiles ('));
      expect(onboardingFunction, contains('legal_name,'));
      expect(onboardingFunction, contains('tax_code,'));
    });

    test('tenant lifecycle defaults to provisioning until activated', () {
      expect(
        sql,
        contains("add column if not exists status text not null default 'provisioning'"),
      );
      expect(
        sql,
        contains("set default 'provisioning'"),
      );
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
