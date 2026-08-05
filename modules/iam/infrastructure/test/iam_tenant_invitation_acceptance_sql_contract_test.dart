import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String sql;

  setUpAll(() {
    final root = _findRepoRoot();
    sql = File(
      '${root.path}/supabase/migrations/_drafts/020_iam_tenant_invitation_acceptance.sql',
    ).readAsStringSync();
  });

  group('iam invitation acceptance SQL contract', () {
    test('defines inspect/accept/decline RPCs', () {
      expect(sql, contains('create or replace function iam.inspect_invitation_token('));
      expect(sql, contains('create or replace function iam.accept_invitation('));
      expect(sql, contains('create or replace function iam.decline_invitation('));
      expect(
        sql,
        contains(
          'Touches: iam.inspect_invitation_token, iam.accept_invitation, iam.decline_invitation',
        ),
      );
    });

    test('raises stable invitation / tenant blocked codes', () {
      for (final code in const [
        'INVITATION_TOKEN_INVALID',
        'INVITATION_EXPIRED',
        'INVITATION_REVOKED',
        'INVITATION_ALREADY_USED',
        'INVITATION_EMAIL_MISMATCH',
        'TENANT_SUSPENDED',
        'AUTHENTICATION_REQUIRED',
        'DUPLICATE_MEMBERSHIP',
        'IDEMPOTENCY_CONFLICT',
      ]) {
        expect(sql, contains("raise exception '$code'"), reason: code);
      }
    });

    test('accept resolves actor from auth.uid email, not client actorUserId', () {
      expect(sql, contains('auth.uid()'));
      expect(sql, contains('from auth.users u'));
      expect(sql, contains('INVITATION_EMAIL_MISMATCH'));
      expect(sql, contains('create or replace function iam.accept_invitation('));
      expect(sql, contains('p_token text'));
      expect(sql, contains('p_idempotency_key text'));
      expect(sql, isNot(contains('actorUserId')));
      expect(sql, isNot(contains('p_actor_user_id uuid')));
    });

    test('suspended tenant does not consume token before raise', () {
      final tenantInviteBranch = sql.substring(
        sql.indexOf('select * into v_tenant from iam.tenants t where t.id = v_inv.tenant_id'),
        sql.indexOf("p_event_code => 'tenant.invitation.accepted'"),
      );
      final suspendIdx = tenantInviteBranch.indexOf("raise exception 'TENANT_SUSPENDED'");
      final consumeIdx = tenantInviteBranch.indexOf(
        "update iam.tenant_invitations\n  set\n    status = 'accepted'",
      );
      expect(suspendIdx, greaterThan(0));
      expect(consumeIdx, greaterThan(suspendIdx));
    });

    test('owner activation code is accepted by invitation RPCs', () {
      final inspectFn = sql.substring(
        sql.indexOf('create or replace function iam.inspect_invitation_token('),
        sql.indexOf('create or replace function iam.accept_invitation('),
      );
      expect(inspectFn, contains('iam.owner_activations'));
      expect(inspectFn, contains("'initial_role_id', 'owner'"));
      expect(inspectFn, contains("'initial_role_label', 'Chủ sở hữu'"));

      final acceptFn = sql.substring(
        sql.indexOf('create or replace function iam.accept_invitation('),
        sql.indexOf('create or replace function iam.decline_invitation('),
      );
      expect(acceptFn, contains('from iam.owner_activations oa'));
      expect(acceptFn, contains("role = 'owner'"));
      expect(acceptFn, contains("status = 'active'"));
      expect(acceptFn, contains('iam._membership_detail_json(v_membership)'));
    });

    test('first tenant invitation accepted into an ownerless tenant becomes owner', () {
      final inspectFn = sql.substring(
        sql.indexOf('create or replace function iam.inspect_invitation_token('),
        sql.indexOf('create or replace function iam.accept_invitation('),
      );
      expect(inspectFn, contains('v_should_be_owner := not exists'));
      expect(
        inspectFn,
        contains(
          "'initial_role_label', case when v_should_be_owner then 'Chủ sở hữu'",
        ),
      );

      final acceptFn = sql.substring(
        sql.indexOf('create or replace function iam.accept_invitation('),
        sql.indexOf('create or replace function iam.decline_invitation('),
      );
      expect(acceptFn, contains('v_effective_role := case'));
      expect(acceptFn, contains("when v_should_be_owner then 'owner'"));
      expect(acceptFn, contains('v_effective_role = \'owner\''));
      expect(acceptFn, isNot(contains("status = 'active',\n          activated_at")));
      expect(acceptFn, isNot(contains("status = case when status = 'provisioning'")));
    });

    test('invalid inspect path does not build account_exists success payload', () {
      expect(sql, contains("'account_exists', v_account_exists"));
      // Token invalid raises before returning jsonb with account_exists.
      expect(sql, contains("raise exception 'INVITATION_TOKEN_INVALID'"));
    });

    test('grants inspect/decline to anon for logged-out flows', () {
      // EXECUTE is inert without schema USAGE — the foundation migration
      // revokes schema iam from anon, so S8 must grant it back or PostgREST
      // answers 42501 `permission denied for schema iam`.
      expect(sql, contains('grant usage on schema iam to anon'));
      expect(
        sql,
        contains(
          'grant execute on function iam.inspect_invitation_token(text) to anon, authenticated',
        ),
      );
      expect(
        sql,
        contains(
          'grant execute on function iam.decline_invitation(text, text) to anon, authenticated',
        ),
      );
      expect(
        sql,
        contains(
          'grant execute on function iam.accept_invitation(text, text) to authenticated',
        ),
      );
    });

    test('decline returns stored delivery projection and declined_at', () {
      final declineFn = sql.substring(
        sql.indexOf('create or replace function iam.decline_invitation('),
      );
      expect(declineFn, contains("'declined_at', v_now"));
      expect(declineFn, contains('v_inv.delivery_correlation_id'));
      expect(declineFn, contains('v_inv.last_sent_at'));
      expect(declineFn, contains('iam.email_delivery_outcomes'));
      expect(declineFn, isNot(contains("'delivery_correlation_id', ''")));
      expect(declineFn, isNot(contains("'last_sent_at', null")));
      expect(declineFn, isNot(contains("'token'")));
      expect(declineFn, isNot(contains("'token_hash'")));
    });

    test('token hash normalises case and separators', () {
      final fn = sql.substring(
        sql.indexOf('create or replace function iam._invitation_token_hash('),
      );
      // Bỏ ký tự không thuộc bảng chữ (gạch/space) rồi viết HOA trước khi băm.
      expect(fn, contains('upper('));
      expect(fn, contains("regexp_replace"));
      expect(fn, contains("'[^0-9A-Za-z]'"));
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
