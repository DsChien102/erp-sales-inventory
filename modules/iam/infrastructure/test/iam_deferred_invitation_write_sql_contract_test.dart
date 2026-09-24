import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String sql;

  setUpAll(() {
    final root = findRepoRoot();
    const files = [
      '20260916005_iam_patch_invitation_membership_store_scope.sql',
      '20260916004_iam_patch_onboarding_default_store_scope.sql',
      '20260911006_iam_reinvite_provisioning_owner.sql',
      '20260916006_iam_patch_accept_invitation_default_store_scope.sql',
    ];
    sql = files
        .map((f) => File('${root.path}/supabase/migrations/$f').readAsStringSync())
        .join('\n');
  });

  test('send paths never materialize profiles or memberships', () {
    for (final fn in const [
      'iam.create_tenant_invitation',
      'iam.create_tenant_onboarding',
      'iam.reinvite_provisioning_owner',
    ]) {
      final body = functionBody(sql, fn);
      expect(body, isNot(contains('insert into iam.platform_user_profiles')), reason: fn);
      expect(body, isNot(contains('insert into iam.memberships')), reason: fn);
      expect(body, isNot(contains('update iam.memberships')), reason: fn);
    }
  });

  test('onboarding and reinvite return no pre-accept membership', () {
    final onboarding = functionBody(sql, 'iam.create_tenant_onboarding');
    expect(onboarding, contains("'owner_membership_id', null"));
    expect(onboarding, contains('insert into iam.tenant_invitations'));
    expect(onboarding, contains('iam.enqueue_outbox_message'));

    final reinvite = functionBody(sql, 'iam.reinvite_provisioning_owner');
    expect(reinvite, contains("'owner_membership_id', null"));
    expect(reinvite, contains('update iam.tenant_invitations'));
    expect(reinvite, contains('iam.enqueue_outbox_message'));
    expect(reinvite, isNot(contains('insert into iam.tenant_invitations')));
  });

  test('accept upserts the real profile before creating membership', () {
    final body = functionBody(sql, 'iam.accept_invitation');
    final profile = body.indexOf('insert into iam.platform_user_profiles');
    final membership = body.lastIndexOf('insert into iam.memberships');
    final consume = body.lastIndexOf("status = 'accepted'");
    expect(profile, isNonNegative);
    expect(membership, greaterThan(profile));
    expect(consume, greaterThan(membership));
    expect(body, contains('on conflict (user_id) do update'));
    expect(body, contains("when iam.platform_user_profiles.status = 'suspended'"));
    expect(body, contains('v_inv.target_membership_id'));
  });

  test('reinvite reuses the locked owner invitation row', () {
    final body = functionBody(sql, 'iam.reinvite_provisioning_owner');
    expect(body, contains('for update'));
    expect(body, contains("v_inv.status not in ('pending', 'expired')"));
    expect(body, contains("raise exception 'INVITATION_ALREADY_USED'"));
    expect(body, contains('update iam.tenant_invitations'));
    expect(body, contains('last_sent_at = v_now'));
    expect(body, contains("when v_prev_status = 'expired' then v_now"));
    expect(body, contains('else status_changed_at'));
    expect(body, isNot(contains("set status = 'expired'")));
    expect(body, isNot(contains('insert into iam.tenant_invitations')));
  });

  test('reinvite preserves invitee metadata when email changes', () {
    final body = functionBody(sql, 'iam.reinvite_provisioning_owner');
    final updateStart = body.indexOf('update iam.tenant_invitations');
    final updateEnd = body.indexOf('where id = v_inv.id', updateStart);
    expect(updateStart, isNonNegative);
    expect(updateEnd, greaterThan(updateStart));

    final updateClause = body.substring(updateStart, updateEnd);
    expect(updateClause, contains('invitee_email = v_owner_email'));
    expect(updateClause, contains("status = 'pending'"));
    expect(updateClause, contains('token_hash = v_code_hash'));
    expect(updateClause, contains("expires_at = v_now + interval '7 days'"));
    expect(updateClause, contains('version = version + 1'));
    expect(updateClause, contains('updated_at = v_now'));
    expect(updateClause, contains('delivery_correlation_id = v_correlation'));
    expect(updateClause, contains('last_sent_at = v_now'));
    expect(updateClause, contains('accepted_membership_id = null'));
    expect(updateClause, contains('target_membership_id = null'));
    expect(updateClause, isNot(contains('initial_role_id =')));
    expect(updateClause, isNot(contains('given_name =')));
    expect(updateClause, isNot(contains('family_name =')));
    expect(updateClause, isNot(contains('phone =')));
    expect(updateClause, isNot(contains('created_at =')));
    expect(
      body,
      isNot(contains('lower(v_owner_email) = lower(v_inv.invitee_email)')),
    );
    expect(body, contains('i.id <> v_inv.id'));
  });
}

String functionBody(String sql, String qualifiedName) {
  final start = sql.lastIndexOf(
    'create or replace function $qualifiedName(',
  );
  if (start < 0) throw StateError('$qualifiedName not found');
  final end = sql.indexOf(r'$$;', start);
  if (end < 0) throw StateError('$qualifiedName terminator not found');
  return sql.substring(start, end + 3);
}

Directory findRepoRoot() {
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
