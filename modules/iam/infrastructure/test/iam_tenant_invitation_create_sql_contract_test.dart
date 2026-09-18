import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String sql;

  setUpAll(() {
    final root = _findRepoRoot();
    sql = File(
      '${root.path}/supabase/migrations/20260811017_iam_tenant_invitation_create.sql',
    ).readAsStringSync();
  });

  group('iam.create_tenant_invitation SQL contract', () {
    test('defines create RPC and invitation table', () {
      expect(sql, contains('create table if not exists iam.tenant_invitations'));
      expect(
        sql,
        isNot(contains('create table if not exists iam.tenant_invitation_operations')),
      );
      expect(sql, contains('create or replace function iam.create_tenant_invitation('));
      expect(sql, contains('Touches: iam.create_tenant_invitation'));
    });

    test('enforces business blocked codes', () {
      for (final code in const [
        'AUTHENTICATION_REQUIRED',
        'PERMISSION_DENIED',
        'VALIDATION_ERROR',
        'ROLE_NOT_ASSIGNABLE',
        'DUPLICATE_MEMBERSHIP',
        'MEMBERSHIP_INACTIVE',
        'INVITATION_PENDING_EXISTS',
        'IDEMPOTENCY_CONFLICT',
      ]) {
        expect(sql, contains("raise exception '$code'"), reason: code);
      }
    });

    test('persists token_hash only and uses 7-day expiry', () {
      expect(sql, contains('v_token_hash := iam._invitation_token_hash(v_raw_token);'));
      expect(sql, contains("interval '7 days'"));
      expect(sql, contains('token_hash text not null'));
      expect(sql, isNot(contains('invitation_token text')));
      expect(
        sql.contains('v_token_hash') && sql.contains('v_actor_membership.id'),
        isTrue,
      );
    });

    test('enqueues tenant_invitation with secret ciphertext, not refs token', () {
      expect(sql, contains("'template_id', 'tenant_invitation'"));
      expect(sql, contains("'secret_payload_ciphertext', v_ciphertext"));
      expect(sql, contains("iam.enqueue_outbox_message("));
      expect(sql, contains("iam.record_email_delivery_outcome("));
      expect(sql, contains("p_status := 'queued'"));
      expect(sql, isNot(contains("'refs', jsonb_build_object(\n        'token'")));
      expect(sql, isNot(contains("'invitation_token'")));
    });

    test('idempotent replay and payload conflict', () {
      expect(sql, contains('v_existing_op.payload_hash <> v_payload_hash'));
      expect(sql, contains('return v_existing_op.result'));
    });

    test('returns InvitationDetailDto wire keys', () {
      for (final key in const [
        'invitation_id',
        'invitee_email',
        'initial_role_id',
        'initial_role_label',
        'status',
        'expires_at',
        'delivery_status',
        'delivery_correlation_id',
        'version',
        'created_at',
        'created_by',
        'last_sent_at',
      ]) {
        expect(sql, contains("'$key'"), reason: key);
      }
    });

    test('persists readable delivery projection on invitation row', () {
      expect(sql, contains('delivery_correlation_id text'));
      expect(sql, contains('last_sent_at timestamptz'));
      final insertBlock = sql.substring(
        sql.indexOf('insert into iam.tenant_invitations ('),
        sql.indexOf('returning * into v_invitation;'),
      );
      expect(insertBlock, contains('delivery_correlation_id'));
      expect(insertBlock, contains('last_sent_at'));
      expect(insertBlock, contains('v_correlation_id'));
      final resultBlock = sql.substring(
        sql.indexOf('v_result := jsonb_build_object('),
        sql.indexOf('insert into iam.tenant_invitation_operations ('),
      );
      expect(resultBlock, isNot(contains("'token'")));
      expect(resultBlock, isNot(contains("'token_hash'")));
    });

    test('defines a Crockford Base32 code generator', () {
      expect(sql, contains('function iam._generate_invitation_code()'));
      // Bảng chữ 32 ký tự, bỏ I/L/O/U.
      expect(sql, contains('0123456789ABCDEFGHJKMNPQRSTVWXYZ'));
      // Sinh ngẫu nhiên mã hoá, không dùng random() thường.
      expect(sql, contains('gen_random_bytes'));
    });

    test('defines canonical token hash shared by create and inspect', () {
      expect(sql, contains('create or replace function iam._invitation_token_hash('));
      expect(sql, contains('upper('));
      expect(sql, contains('regexp_replace'));
      expect(sql, contains("'[^0-9A-Za-z]'"));
      expect(sql, contains('v_token_hash := iam._invitation_token_hash(v_raw_token);'));
    });

    test('create uses the code generator, not a 32-byte base64url token', () {
      final fn = sql.substring(
        sql.indexOf('create or replace function iam.create_tenant_invitation('),
      );
      expect(fn, contains('iam._generate_invitation_code()'));
      expect(fn, isNot(contains('gen_random_bytes(32)')));
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
