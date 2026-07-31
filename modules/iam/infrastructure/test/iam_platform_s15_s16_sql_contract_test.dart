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
        name: File('${root.path}/supabase/migrations/_drafts/$name')
            .readAsStringSync(),
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
