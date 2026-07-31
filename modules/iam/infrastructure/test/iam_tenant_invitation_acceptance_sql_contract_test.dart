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
      final suspendIdx = sql.indexOf("raise exception 'TENANT_SUSPENDED'");
      final consumeIdx = sql.indexOf("status = 'accepted'");
      expect(suspendIdx, greaterThan(0));
      expect(consumeIdx, greaterThan(suspendIdx));
    });

    test('invalid inspect path does not build account_exists success payload', () {
      expect(sql, contains("'account_exists', v_account_exists"));
      // Token invalid raises before returning jsonb with account_exists.
      expect(sql, contains("raise exception 'INVITATION_TOKEN_INVALID'"));
    });

    test('grants inspect/decline to anon for logged-out flows', () {
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
