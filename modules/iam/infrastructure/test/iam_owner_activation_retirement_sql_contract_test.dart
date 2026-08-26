import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String sql;

  setUpAll(() {
    final root = _findRepoRoot();
    sql = File(
      '${root.path}/supabase/migrations/_drafts/006_iam_audit_owner_activation_cleanup.sql',
    ).readAsStringSync();
  });

  // Slice from the function header to the END of its body (`\$\$;`) so trailing
  // comments/drop-statements of later blocks do not leak into the slice.
  String bodyOf(String header) {
    final start = sql.indexOf(header);
    if (start < 0) return '';
    final end = sql.indexOf(r'$$;', start);
    return end < 0 ? sql.substring(start) : sql.substring(start, end);
  }

  group('owner is first user — unified with staff invitation (Design A)', () {
    test('tenant_invitations can hold an owner invitation (is_owner + nullable inviter)', () {
      expect(sql, contains('alter table iam.tenant_invitations'));
      expect(sql, contains('add column if not exists is_owner boolean'));
      expect(sql, contains('alter column invited_by_membership_id drop not null'));
      expect(sql, contains('tenant_invitations_owner_inviter_chk'));
    });

    test('pending platform profile is materialised at onboarding (account in the '
        'system before activation)', () {
      // FK relaxed + email column so a placeholder profile can exist before auth.users.
      expect(sql, contains('drop constraint if exists platform_user_profiles_user_id_fkey'));
      expect(sql, contains('add column if not exists email text'));
      // Onboarding creates the pending profile.
      final fn = bodyOf('create or replace function iam.create_tenant_onboarding(');
      expect(fn, contains('insert into iam.platform_user_profiles'));
      expect(fn, contains("'pending_activation'"));
      // Trigger reconciles the placeholder when the owner signs up.
      expect(sql, contains('_cleanup_pending_profile_on_auth_user'));
      expect(sql, contains('after insert on auth.users'));
    });

    test('onboarding issues an owner invitation with a code, not a membership, '
        'not owner_activations', () {
      final fn = bodyOf('create or replace function iam.create_tenant_onboarding(');
      expect(fn, isNotEmpty);
      expect(fn, contains('insert into iam.tenant_invitations'));
      expect(fn, contains('is_owner'));
      expect(fn, contains("'template_id', 'activation_invitation'"));
      // Prefill: owner name entered at onboarding is carried on the invitation.
      expect(fn, contains('given_name'));
      // Membership is created at accept (accept_invitation), not at onboarding.
      expect(fn, isNot(contains('insert into iam.memberships')));
      expect(fn, isNot(contains('owner_activations')));
    });

    test('accept_invitation has no owner_activations fallback (owner goes through '
        'the shared tenant_invitations path)', () {
      final fn = bodyOf('create or replace function iam.accept_invitation(');
      expect(fn, isNotEmpty);
      expect(fn, isNot(contains('owner_activations')));
      // First active member becomes the owner via v_should_be_owner.
      expect(fn, contains('v_should_be_owner'));
      expect(fn, contains("'store_owner'"));
      // Owner accept also (re)creates the platform_user_profiles row.
      expect(fn, contains('insert into iam.platform_user_profiles'));
    });

    test('inspect_invitation_token has no owner_activations fallback and '
        'returns the owner prefill', () {
      final fn = bodyOf('create or replace function iam.inspect_invitation_token(');
      expect(fn, isNotEmpty);
      expect(fn, isNot(contains('owner_activations')));
      expect(fn, contains('v_inv.given_name'));
    });

    test('legacy owner activation storage and RPCs are dropped', () {
      expect(sql, contains('drop function if exists iam.inspect_owner_activation(text)'));
      expect(sql, contains('drop function if exists iam.accept_owner_activation(text, text)'));
      expect(sql, contains('drop table if exists iam.owner_activations'));
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
