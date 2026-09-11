import 'dart:io';

import 'package:test/test.dart';

void main() {
  late final Map<String, String> drafts;

  setUpAll(() {
    final root = _findRepoRoot();
    final mapping = {
      '004_iam_platform_users_read.sql': '20260811004_iam_platform_users_read.sql',
      '005_iam_platform_user_lifecycle.sql': '20260811005_iam_platform_user_lifecycle.sql',
      '006_iam_create_tenant_onboarding.sql': '20260811006_iam_create_tenant_onboarding.sql',
      '010_iam_platform_tenants_read.sql': '20260811010_iam_platform_tenants_read.sql',
      '011_iam_platform_tenant_lifecycle.sql': '20260811011_iam_platform_tenant_lifecycle.sql',
      '012_iam_platform_transfer_ownership.sql': '20260811012_iam_platform_transfer_ownership.sql',
      '013_iam_platform_audit_read.sql': '20260811013_iam_platform_audit_read.sql',
    };
    drafts = {
      for (final entry in mapping.entries)
        entry.key: File('${root.path}/supabase/migrations/${entry.value}').readAsStringSync(),
      '005_iam_get_platform_tenant_owner_from_invitation.sql': File(
        '${root.path}/supabase/migrations/_drafts/005_iam_get_platform_tenant_owner_from_invitation.sql',
      ).readAsStringSync(),
      '006_iam_onboarding_owner_membership_with_invitation.sql': File(
        '${root.path}/supabase/migrations/_drafts/006_iam_onboarding_owner_membership_with_invitation.sql',
      ).readAsStringSync(),
      '007_iam_hybrid_owner_accept_decline_unwind.sql': File(
        '${root.path}/supabase/migrations/_drafts/007_iam_hybrid_owner_accept_decline_unwind.sql',
      ).readAsStringSync(),
      '008_iam_reinvite_provisioning_owner.sql': File(
        '${root.path}/supabase/migrations/_drafts/008_iam_reinvite_provisioning_owner.sql',
      ).readAsStringSync(),
    };
  });

  test('004/010/013 search contracts include cursor page params', () {
    expect(drafts['004_iam_platform_users_read.sql'], contains('p_cursor'));
    expect(drafts['004_iam_platform_users_read.sql'], contains('p_page_size'));
    expect(drafts['010_iam_platform_tenants_read.sql'], contains('p_cursor'));
    expect(
      drafts['010_iam_platform_tenants_read.sql'],
      contains('p_readiness_state'),
    );
    expect(drafts['013_iam_platform_audit_read.sql'], contains('p_page_size'));
    expect(
      drafts['013_iam_platform_audit_read.sql'],
      contains('p_correlation_id'),
    );
  });

  test('010 tenant cursor search returns rows from tenants table', () {
    final sql = drafts['010_iam_platform_tenants_read.sql']!;

    expect(sql, contains('from iam.tenants t'));
    expect(sql, contains('jsonb_agg'));
    expect(sql, contains('owner_name'));
    expect(sql, contains('member_count'));
    expect(sql, isNot(contains("jsonb_build_object('items', '[]'::jsonb")));
  });

  test('010 tenant member reads return one active membership per user', () {
    final sql = drafts['010_iam_platform_tenants_read.sql']!;

    expect(sql, contains('distinct on (m.user_id)'));
    expect(sql, contains("coalesce(m.status, 'active') = 'active'"));
    expect(sql, contains('order by m.user_id, m.is_owner desc, m.created_at desc'));
  });

  test('010 tenant detail members expose DB role labels', () {
    final sql = drafts['010_iam_platform_tenants_read.sql']!;

    expect(sql, contains("'role_label', m.role_label"));
    expect(sql, contains('coalesce(rd.label, m.role::text) as role_label'));
    expect(sql, contains('left join iam.role_definitions rd on rd.code = m.role'));
  });

  test('010 tenant detail preserves DB role labels', () {
    final sql = drafts['010_iam_platform_tenants_read.sql']!;

    expect(sql, contains("'role_label', m.role_label"));
    expect(sql, contains('coalesce(rd.label, m.role::text) as role_label'));
    expect(sql, contains('left join iam.role_definitions rd on rd.code = m.role'));
  });

  test('010 get_platform_tenant returns optimistic concurrency version', () {
    final sql = drafts['010_iam_platform_tenants_read.sql']!;

    expect(sql, contains("coalesce(t.version, 1) as version"));
    expect(sql, contains("'version', v_tenant.version"));
  });

  test('011 restore_platform_tenant clears suspend fields on version match', () {
    final sql = drafts['011_iam_platform_tenant_lifecycle.sql']!;

    expect(sql, contains('suspended_at = null'));
    expect(sql, contains('suspend_reason = null'));
    expect(sql, contains('suspended_by = null'));
    expect(sql, contains('updated_at = now()'));
    expect(sql, contains("v_status <> 'suspended'"));
    expect(sql, contains('v_activated_at timestamptz'));
    expect(sql, contains('coalesce(version, 1), activated_at'));
    expect(sql, contains('if v_activated_at is null then'));
    expect(sql, contains("set status = 'active'"));
    expect(sql, isNot(contains('activated_at = coalesce(activated_at, now())')));
  });

  test('011 versioned suspend persists reason actor and audit', () {
    final sql = drafts['011_iam_platform_tenant_lifecycle.sql']!;

    expect(sql, contains("if v_status <> 'active' then"));
    expect(sql, contains('suspend_reason = trim(p_reason)'));
    expect(sql, contains('suspended_by = v_actor'));
    expect(sql, contains('updated_at = now()'));
    expect(sql, contains("'iam.tenant.suspended'"));
  });

  test('010 get_platform_tenant resolves platform metadata fields', () {
    final sql = drafts['010_iam_platform_tenants_read.sql']!;

    expect(sql, contains("'suspended_by', ("));
    expect(sql, contains('where u.id = v_tenant.suspended_by'));
    expect(sql, contains('add column if not exists updated_at'));
    expect(
      sql,
      contains(
        "'last_activity_at', coalesce(v_tenant.updated_at, v_tenant.activated_at, v_tenant.created_at)",
      ),
    );
  });

  test(
    'draft get_platform_tenant owner from membership + profiles '
    '(no invitation path)',
    () {
      final sql =
          drafts['005_iam_get_platform_tenant_owner_from_invitation.sql']!;

      expect(sql, contains('create or replace function iam.get_platform_tenant'));
      expect(sql, contains('Touches: iam.get_platform_tenant'));
      expect(sql, contains('iam.platform_user_profiles'));
      expect(
        sql,
        contains("concat_ws(' ', p.family_middle_name, p.given_name)"),
      );
      expect(
        sql,
        contains('join iam.platform_user_profiles p on p.user_id = m.user_id'),
      );
      expect(sql, isNot(contains('iam.tenant_invitations')));
      expect(sql, isNot(contains('invitee_email')));
      expect(sql, isNot(contains("v_tenant.status = 'provisioning'")));
    },
  );

  test('draft onboarding creates owner membership with invitation', () {
    final sql =
        drafts['006_iam_onboarding_owner_membership_with_invitation.sql']!;

    expect(sql, contains('create or replace function iam.create_tenant_onboarding'));
    expect(sql, contains("'store_owner'"));
    expect(sql, contains('is_owner'));
    expect(sql, contains("'owner_membership_id', v_membership_id"));
    expect(sql, contains('iam.tenant_invitations'));
    expect(sql, contains('drop constraint if exists memberships_user_id_fkey'));
  });

  test('draft accept/decline unwind provisioning owner membership', () {
    final sql = drafts['007_iam_hybrid_owner_accept_decline_unwind.sql']!;

    expect(sql, contains('iam._unwind_provisioning_owner_membership'));
    expect(sql, contains("status = 'removed'"));
    expect(sql, contains("v_status <> 'provisioning'"));
    expect(sql, contains('v_inv.is_owner is true'));
    expect(sql, contains('v_linked_existing'));
  });

  test('draft reinvite_provisioning_owner assigns owner again', () {
    final sql = drafts['008_iam_reinvite_provisioning_owner.sql']!;

    expect(sql, contains('create or replace function iam.reinvite_provisioning_owner'));
    expect(sql, contains('OWNER_ALREADY_ASSIGNED'));
    expect(sql, contains("'tenant_status', 'provisioning'"));
    expect(sql, contains("'owner_membership_id', v_membership_id"));
  });

  test('005/011/012 lifecycle include version + idempotency', () {
    expect(
      drafts['005_iam_platform_user_lifecycle.sql'],
      contains('p_expected_version'),
    );
    expect(
      drafts['005_iam_platform_user_lifecycle.sql'],
      contains('p_idempotency_key'),
    );
    expect(
      drafts['011_iam_platform_tenant_lifecycle.sql'],
      contains('p_expected_version'),
    );
    expect(
      drafts['011_iam_platform_tenant_lifecycle.sql'],
      contains("TENANT_STATE_INVALID"),
    );
    expect(
      drafts['012_iam_platform_transfer_ownership.sql'],
      contains('p_expected_version'),
    );
    expect(
      drafts['012_iam_platform_transfer_ownership.sql'],
      contains('OWNER_TARGET_INVALID'),
    );
    expect(
      drafts['012_iam_platform_transfer_ownership.sql'],
      contains('IDEMPOTENCY_CONFLICT'),
    );
  });

  test('006 onboarding get/retry operations exist', () {
    final sql = drafts['006_iam_create_tenant_onboarding.sql']!;
    expect(sql, contains('get_tenant_onboarding_operation'));
    expect(sql, contains('retry_tenant_onboarding_operation'));
    expect(sql, contains('completed_steps'));
    expect(sql, contains('failed_step'));
  });

  test('005 draft get_platform_tenant keeps owner_email_verified (merged 003)', () {
    final sql = drafts['005_iam_get_platform_tenant_owner_from_invitation.sql']!;
    expect(sql, contains('coalesce(p.email_verified, false) as owner_email_verified'));
    expect(sql, contains("'owner_email_verified', coalesce(v_owner.owner_email_verified, false)"));
    expect(sql, isNot(contains('email_confirmed_at')));
    expect(sql, isNot(contains("'unverified_email'")));
  });

  test('007 draft accept_invitation keeps anon grant and resolve (merged 004)', () {
    final sql = drafts['007_iam_hybrid_owner_accept_decline_unwind.sql']!;
    final acceptFn = sql.substring(
      sql.indexOf('create or replace function iam.accept_invitation('),
      sql.indexOf('create or replace function iam.decline_invitation('),
    );
    expect(acceptFn, isNot(contains("raise exception 'AUTHENTICATION_REQUIRED'")));
    expect(acceptFn, contains('Resolve caller'));
    expect(acceptFn, contains('iam.user_preferences'));
    expect(
      sql,
      contains(
        'grant execute on function iam.accept_invitation(text, text) to anon, authenticated',
      ),
    );
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
