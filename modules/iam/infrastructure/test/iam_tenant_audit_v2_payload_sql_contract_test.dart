import 'dart:io';

import 'package:test/test.dart';

void main() {
  late Directory drafts;

  setUpAll(() {
    drafts = Directory('${_findRepoRoot().path}/supabase/migrations/_drafts');
  });

  String readDraft(String name) => File('${drafts.path}/$name').readAsStringSync();

  group('004_iam_tenant_audit_history_v2_payloads.sql contract', () {
    test('file exists and conforms to migration draft policy headers', () {
      final sql = readDraft('004_iam_tenant_audit_history_v2_payloads.sql');
      expect(sql, contains('-- Kind: patch'));
      expect(sql, contains('-- Intent: iam_tenant_audit_history_v2_payloads'));
      expect(
        sql,
        contains(
          '-- Touches: iam.update_tenant_profile, iam.upsert_legal_profile, iam.update_my_platform_user_profile, iam.resend_tenant_invitation, iam.revoke_tenant_invitation, iam.accept_invitation',
        ),
      );
    });

    test('update_tenant_profile captures pre-mutation before state and after state', () {
      final sql = readDraft('004_iam_tenant_audit_history_v2_payloads.sql');
      expect(sql, contains('function iam.update_tenant_profile('));
      expect(sql, contains('p_event_code => \'iam.tenant.profile_updated\''));
      expect(sql, contains('p_before => v_audit_before'));
      expect(sql, contains('p_after => jsonb_build_object('));
    });

    test('upsert_legal_profile captures before and masks tax_code', () {
      final sql = readDraft('004_iam_tenant_audit_history_v2_payloads.sql');
      expect(sql, contains('function iam.upsert_legal_profile('));
      expect(sql, contains('p_event_code => \'iam.tenant.legal_profile_updated\''));
      expect(sql, contains('tax_code_masked'));
      expect(sql, contains('p_before => v_audit_before'));
      expect(sql, isNot(contains('iam._legal_profile_json')));
      expect(sql, contains("'tenant_version', v_row.version"));
      expect(sql, contains("'profile', jsonb_build_object("));
      expect(
        sql,
        contains('version = iam.tenant_legal_profiles.version + 1'),
      );
    });

    test('legal profile masks registered address before audit persistence', () {
      final sql = readDraft('004_iam_tenant_audit_history_v2_payloads.sql');
      final functionStart = sql.indexOf(
        'create or replace function iam.upsert_legal_profile(',
      );
      final functionEnd = sql.indexOf(
        '-- ── 3. update_my_platform_user_profile',
        functionStart,
      );
      expect(functionStart, greaterThanOrEqualTo(0));
      expect(functionEnd, greaterThan(functionStart));
      final functionBody = sql.substring(functionStart, functionEnd);
      final auditStart = functionBody.indexOf('v_audit_before :=');
      final returnStart = functionBody.indexOf(
        'return jsonb_build_object(',
        auditStart,
      );
      expect(auditStart, greaterThanOrEqualTo(0));
      expect(returnStart, greaterThan(auditStart));
      final auditPersistence = functionBody.substring(auditStart, returnStart);

      expect(
        auditPersistence,
        isNot(contains("'registered_address_text',")),
      );
      expect(
        "'registered_address_masked'".allMatches(auditPersistence),
        hasLength(2),
      );
      expect(
        auditPersistence,
        contains("'before.registered_address_text'"),
      );
      expect(
        auditPersistence,
        contains("'after.registered_address_text'"),
      );
    });

    test('update_my_platform_user_profile captures before and masks phone', () {
      final sql = readDraft('004_iam_tenant_audit_history_v2_payloads.sql');
      expect(sql, contains('function iam.update_my_platform_user_profile('));
      expect(sql, contains('p_event_code => \'iam.account.profile_updated\''));
      expect(sql, contains('phone_masked'));
      expect(sql, contains('p_before => v_audit_before'));
    });

    test('invitation lifecycle captures before/after with canonical event codes', () {
      final sql = readDraft('004_iam_tenant_audit_history_v2_payloads.sql');
      expect(sql, contains('function iam.resend_tenant_invitation('));
      expect(sql, contains('p_event_code => \'iam.tenant.invitation_resent\''));
      expect(sql, contains('function iam.revoke_tenant_invitation('));
      expect(sql, contains('p_event_code => \'iam.tenant.invitation_revoked\''));
      expect(sql, contains('function iam.accept_invitation('));
      expect(sql, contains('p_event_code => \'iam.tenant.invitation_accepted\''));
    });

    test('accept_invitation preserves the canonical signature and behavior', () {
      final sql = readDraft('004_iam_tenant_audit_history_v2_payloads.sql');
      final acceptStart = sql.indexOf(
        'create or replace function iam.accept_invitation(',
      );
      expect(acceptStart, greaterThanOrEqualTo(0));
      final accept = sql.substring(acceptStart);

      expect(
        accept,
        startsWith(
          'create or replace function iam.accept_invitation(\n'
          '  p_token text,\n'
          '  p_idempotency_key text\n'
          ')',
        ),
      );
      expect(accept, isNot(contains('p_password')));
      expect(accept, contains('iam.tenant_invitation_token_operations'));
      expect(accept, contains("o.operation = 'accept'"));
      expect(accept, contains('return v_existing.result'));
      expect(accept, contains('from iam.owner_activations oa'));
      expect(accept, contains("raise exception 'TENANT_SUSPENDED'"));
      expect(accept, contains("raise exception 'INVITATION_REVOKED'"));
      expect(accept, contains("token_hash = encode("));
      expect(accept, contains("p_subject_type => 'invitation'"));
      expect(accept, contains('p_subject_id => v_inv.id::text'));
      expect(accept, contains('p_tracking_id => p_idempotency_key'));
    });

    test('masks contact PII before append and flags before/after independently', () {
      final sql = readDraft('004_iam_tenant_audit_history_v2_payloads.sql');
      expect(sql, isNot(contains("'contact_email',")));
      expect(sql, isNot(contains("'contact_phone',")));
      expect(sql, isNot(contains("'phone_number', v_phone")));
      expect(sql, contains("'contact_email_masked'"));
      expect(sql, contains("'contact_phone_masked'"));
      expect(sql, contains("'phone_masked'"));
      expect(sql, contains("'before.contact_email'"));
      expect(sql, contains("'after.contact_email'"));
      expect(sql, contains("'before.contact_phone'"));
      expect(sql, contains("'after.contact_phone'"));
      expect(sql, contains("'before.phone_number'"));
      expect(sql, contains("'after.phone_number'"));
    });

    test('uses canonical identity and invitation schema names', () {
      final sql = readDraft('004_iam_tenant_audit_history_v2_payloads.sql');
      expect(sql, contains('from auth.users'));
      expect(sql, contains('iam.platform_user_profiles'));
      expect(sql, contains('invitee_email'));
      expect(sql, contains('initial_role_id'));
      expect(sql, isNot(contains('iam.platform_users')));
    });

    test('never exposes plaintext token, otp, or secret in audit payloads', () {
      final sql = readDraft('004_iam_tenant_audit_history_v2_payloads.sql');
      expect(sql, isNot(contains("'token', v_raw_token")));
      expect(sql, isNot(contains("'password', p_password")));
      expect(sql, isNot(contains("'token_hash', v_token_hash")));
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
