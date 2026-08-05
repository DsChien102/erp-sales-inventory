import 'dart:io';

import 'package:test/test.dart';

void main() {
  late final Map<String, String> drafts;

  setUpAll(() {
    final root = _findRepoRoot();
    drafts = {
      for (final name in [
        '004_iam_platform_users_read.sql',
        '005_iam_platform_user_lifecycle.sql',
        '006_iam_create_tenant_onboarding.sql',
        '010_iam_platform_tenants_read.sql',
        '011_iam_platform_tenant_lifecycle.sql',
        '012_iam_platform_transfer_ownership.sql',
        '013_iam_platform_audit_read.sql',
      ])
        name: File('${root.path}/supabase/migrations/_drafts/$name').readAsStringSync(),
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
