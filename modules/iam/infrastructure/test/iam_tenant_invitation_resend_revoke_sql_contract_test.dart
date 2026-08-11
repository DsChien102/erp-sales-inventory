import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String sql;

  setUpAll(() {
    final root = _findRepoRoot();
    sql = File(
      '${root.path}/supabase/migrations/20260805021_iam_tenant_invitation_resend_revoke.sql',
    ).readAsStringSync();
  });

  group('iam invitation resend/revoke SQL contract', () {
    test('defines resend and revoke RPCs', () {
      expect(sql, contains('create or replace function iam.resend_tenant_invitation('));
      expect(sql, contains('create or replace function iam.revoke_tenant_invitation('));
      expect(
        sql,
        contains(
          'create or replace function iam.is_current_tenant_invitation_delivery(',
        ),
      );
      expect(
        sql,
        contains(
          'Touches: iam.resend_tenant_invitation, iam.revoke_tenant_invitation,',
        ),
      );
      expect(sql, contains('iam.is_current_tenant_invitation_delivery'));
    });

    test('locks invitation row and checks version / pending', () {
      expect(sql, contains('for update'));
      expect(sql, contains("raise exception 'STATE_CHANGED'"));
      expect(sql, contains("raise exception 'INVITATION_ALREADY_USED'"));
      expect(sql, contains("raise exception 'RESOURCE_NOT_FOUND'"));
      expect(sql, contains('v_inv.version <> p_expected_version'));
      expect(sql, contains("v_inv.status <> 'pending'"));
    });

    test('resend rotates token, 7-day expiry, enqueues one outbox', () {
      expect(sql, contains("interval '7 days'"));
      expect(sql, contains('v_token_hash := iam._invitation_token_hash(v_raw_token);'));
      expect(sql, contains("'template_id', 'tenant_invitation'"));
      expect(sql, contains("'secret_payload_ciphertext', v_ciphertext"));
      expect(sql, contains('iam.enqueue_outbox_message('));
      expect(sql, contains("iam.record_email_delivery_outcome("));
      expect(sql, contains("version = version + 1"));
    });

    test('resend rotates to a generated 8-char code', () {
      final fn = sql.substring(
        sql.indexOf('create or replace function iam.resend_tenant_invitation('),
        sql.indexOf('create or replace function iam.revoke_tenant_invitation('),
      );
      expect(fn, contains('iam._generate_invitation_code()'));
      expect(fn, isNot(contains('gen_random_bytes(32)')));
    });

    test('revoke never enqueues email and stores reason in audit', () {
      final revokeFn = sql.substring(
        sql.indexOf('create or replace function iam.revoke_tenant_invitation('),
      );
      expect(revokeFn, isNot(contains('iam.enqueue_outbox_message(')));
      expect(revokeFn, contains("'revoke_reason', v_reason"));
      expect(revokeFn, contains("status = 'revoked'"));
      expect(
        revokeFn,
        contains(
          'token_hash = encode(extensions.digest(extensions.gen_random_bytes(32)',
        ),
      );
    });

    test('idempotency conflict on different payload', () {
      expect(sql, contains('v_existing.payload_hash <> v_payload_hash'));
      expect(sql, contains("raise exception 'IDEMPOTENCY_CONFLICT'"));
    });

    test('resend updates delivery projection; revoke preserves it', () {
      expect(sql, contains('delivery_correlation_id = v_correlation_id'));
      expect(sql, contains('last_sent_at = v_now'));
      expect(sql, contains('iam.email_delivery_outcomes'));
      expect(sql, contains('(p_inv).delivery_correlation_id'));
      expect(sql, contains('(p_inv).last_sent_at'));
      final revokeFn = sql.substring(
        sql.indexOf('create or replace function iam.revoke_tenant_invitation('),
      );
      final revokeUpdate = revokeFn.substring(
        revokeFn.indexOf('update iam.tenant_invitations'),
        revokeFn.indexOf('returning * into v_inv;'),
      );
      expect(revokeUpdate, isNot(contains('delivery_correlation_id')));
      expect(revokeUpdate, isNot(contains('last_sent_at')));
      expect(revokeUpdate, contains("status = 'revoked'"));
      expect(revokeFn, contains('status_changed_at'));
      expect(sql, isNot(contains("'token_hash'")));
    });

    test('freshness RPC only returns true for pending current correlation', () {
      final fn = sql.substring(
        sql.indexOf(
          'create or replace function iam.is_current_tenant_invitation_delivery(',
        ),
        sql.indexOf('drop function if exists iam._invitation_detail_json('),
      );
      expect(fn, contains('i.delivery_correlation_id = p_correlation_id'));
      expect(fn, contains("i.status = 'pending'"));
      expect(
        sql,
        contains(
          'grant execute on function iam.is_current_tenant_invitation_delivery(uuid, text)',
        ),
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
