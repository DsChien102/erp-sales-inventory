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

  group('iam owner activation retirement contract', () {
    test('legacy owner activation RPCs and table are dropped', () {
      expect(sql, contains('drop function if exists iam.inspect_owner_activation(text)'));
      expect(sql, contains('drop function if exists iam.accept_owner_activation(text, text)'));
      expect(sql, contains('drop table if exists iam.owner_activations'));
    });

    test('onboarding issues an owner invitation via tenant_invitations', () {
      final start = sql.indexOf('create or replace function iam.create_tenant_onboarding(');
      final end = start < 0 ? -1 : sql.indexOf(r'$$;', start);
      final fn = start < 0 ? '' : sql.substring(start, end < 0 ? null : end);
      expect(fn, contains('insert into iam.tenant_invitations'));
      expect(fn, contains('is_owner'));
      expect(fn, isNot(contains('insert into iam.memberships')));
      expect(fn, isNot(contains('owner_activations')));
    });

    test('active platform profiles retain the Auth email', () {
      final acceptStart = sql.indexOf('create or replace function iam.accept_invitation(');
      final acceptEnd = acceptStart < 0 ? -1 : sql.indexOf(r'$$;', acceptStart);
      final acceptFn = acceptStart < 0
          ? ''
          : sql.substring(acceptStart, acceptEnd < 0 ? null : acceptEnd);

      expect(acceptFn, contains('user_id, email, status, email_verified'));
      expect(acceptFn, contains("v_caller, v_email, 'active', true"));
      expect(
        acceptFn,
        contains('email = coalesce(excluded.email, iam.platform_user_profiles.email)'),
      );

      final loginStart = sql.indexOf(
        'create or replace function iam.record_my_platform_login()',
      );
      final loginEnd = loginStart < 0 ? -1 : sql.indexOf(r'$$;', loginStart);
      final loginFn = loginStart < 0
          ? ''
          : sql.substring(loginStart, loginEnd < 0 ? null : loginEnd);
      expect(loginFn, contains('from auth.users u'));
      expect(loginFn, contains('user_id, email, status, last_login_at'));

      expect(sql, contains('update iam.platform_user_profiles p'));
      expect(sql, contains('p.email is distinct from lower(trim(u.email::text))'));
    });

    test('accepted invitation records immutable Audit V2 context', () {
      final start = sql.indexOf('create or replace function iam.accept_invitation(');
      final end = start < 0 ? -1 : sql.indexOf(r'$$;', start);
      final fn = start < 0 ? '' : sql.substring(start, end < 0 ? null : end);

      expect(fn, contains("p_actor_type => 'tenant_member'"));
      expect(fn, contains('p_actor_membership_id => v_membership.id'));
      expect(fn, contains('p_actor_snapshot => jsonb_build_object('));
      expect(fn, contains('p_target_snapshot => jsonb_build_object('));
      expect(fn, contains("p_subject_type => 'tenant'"));
      expect(fn, contains('p_subject_id => v_inv.tenant_id::text'));
      expect(fn, contains('p_target_display_name => v_tenant.display_name'));
      expect(fn, contains('p_target_secondary_identifier => v_tenant.code'));
      expect(fn, contains('p_correlation_id => p_idempotency_key'));
      expect(fn, contains('p_detail_items => jsonb_build_array('));
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
