import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — IAM refactor bảng 3 `iam.memberships`
/// (docs/superpowers/specs/iam-schema-refactor/03-memberships.md).
void main() {
  group('memberships DDL in original migrations', () {
    final lifecycle =
        _readMigration('20260811014_iam_tenant_membership_lifecycle.sql');

    test('adds is_active instead of status; no status check; no partial active index',
        () {
      expect(
        lifecycle,
        contains('add column if not exists is_active boolean not null default true,'),
      );
      expect(
        lifecycle,
        isNot(contains("add column if not exists status text not null default 'active'")),
      );
      expect(lifecycle, isNot(contains('memberships_status_chk')));
      expect(lifecycle, isNot(contains('memberships_tenant_user_active_uidx')));
    });

    test('removed/inactive check and one owner per tenant', () {
      expect(
        lifecycle,
        contains('check (removed_at is null or is_active = false)'),
      );
      expect(
        lifecycle,
        contains(
          'create unique index if not exists memberships_one_owner_per_tenant_uidx\n'
          '  on iam.memberships (tenant_id)\n'
          '  where is_owner and removed_at is null;',
        ),
      );
    });

    test('defines status code helper', () {
      final body = _lastFunctionBlock(lifecycle, 'iam._membership_status_code');
      expect(body, contains("when p_removed_at is not null then 'removed'"));
      expect(body, contains("when p_is_active then 'active'"));
      expect(body, contains("else 'inactive'"));
    });

    test('platform tenants read no longer adds memberships.status', () {
      final sql = _readMigration('20260811010_iam_platform_tenants_read.sql');
      expect(
        sql,
        isNot(
          contains(
            "add column if not exists status text not null default 'active';\n\ncreate or replace function iam.get_platform_tenant",
          ),
        ),
      );
      expect(
        sql,
        contains(
          'alter table iam.memberships\n  add column if not exists is_owner boolean not null default false;',
        ),
      );
    });

    test('role FK after role catalog canonicalization', () {
      final sql =
          _readMigration('20260811024_iam_patch_owner_role_canonicalization.sql');
      expect(
        sql,
        contains('foreign key (role) references iam.role_definitions (code)'),
      );
    });

    test('executed statements use is_active', () {
      expect(
        _readMigration('20260820007_iam_clear_stale_last_selected_tenant.sql'),
        contains('and m.is_active is not true'),
      );
      expect(
        _readMigration('20260916003_iam_backfill_default_store_scopes.sql'),
        isNot(contains('m.status')),
      );
    });
  });

  group('core membership rpcs (final definitions)', () {
    const owners = {
      'iam._mutate_membership_status':
          '20260811014_iam_tenant_membership_lifecycle.sql',
      'iam._membership_detail_json':
          '20260820004_iam_tenant_member_detail_user_info.sql',
      'iam._unwind_staff_precreate_membership':
          '20260916005_iam_patch_invitation_membership_store_scope.sql',
      'iam._unwind_provisioning_owner_membership':
          '20260911005_iam_hybrid_owner_accept_decline_unwind.sql',
      'iam.transfer_platform_tenant_ownership':
          '20260811012_iam_platform_transfer_ownership.sql',
      'iam.assign_member_role': '20260820005_iam_assign_member_role_fix.sql',
      'iam.has_permission':
          '20260811024_iam_patch_owner_role_canonicalization.sql',
    };
    String body(String fn) => _lastFunctionBlock(_readMigration(owners[fn]!), fn);

    test('rewritten per rules', () => _expectRewritten(owners));

    test('mutate writes is_active and removed_at', () {
      final b = body('iam._mutate_membership_status');
      expect(b, contains("set is_active = (p_target_status = 'active'),"));
      expect(
        b,
        contains(
          "removed_at = case when p_target_status = 'removed' then v_now else null end,",
        ),
      );
      expect(
        b,
        contains(
          'v_current_status := iam._membership_status_code(v_row.is_active, v_row.removed_at);',
        ),
      );
    });

    test('detail json keeps status and removed_at keys', () {
      final b = body('iam._membership_detail_json');
      expect(
        b,
        contains(
          "'status', iam._membership_status_code(p_membership.is_active, p_membership.removed_at),",
        ),
      );
      expect(b, contains("'removed_at', p_membership.removed_at"));
    });

    test('unwinds deactivate, stamp removal and bump version', () {
      for (final fn in [
        'iam._unwind_staff_precreate_membership',
        'iam._unwind_provisioning_owner_membership',
      ]) {
        expect(body(fn), contains('is_active = false'), reason: fn);
        expect(body(fn), contains('removed_at = v_now'), reason: fn);
        expect(body(fn), contains('status_changed_at = v_now'), reason: fn);
        expect(body(fn), contains('version = version + 1'), reason: fn);
      }
    });

    test('transfer clears old owner before setting new owner', () {
      final b = body('iam.transfer_platform_tenant_ownership');
      expect(
        b.indexOf('set is_owner = true'),
        greaterThan(b.indexOf('set is_owner = false')),
      );
      expect(b.indexOf('set is_owner = false'), isNonNegative);
    });
  });

  group('invitation and session rpcs (final definitions)', () {
    const owners = {
      'iam.accept_invitation':
          '20260916006_iam_patch_accept_invitation_default_store_scope.sql',
      'iam.create_tenant_invitation':
          '20260916005_iam_patch_invitation_membership_store_scope.sql',
      'iam.create_tenant_onboarding':
          '20260916004_iam_patch_onboarding_default_store_scope.sql',
      'iam.reinvite_provisioning_owner':
          '20260911006_iam_reinvite_provisioning_owner.sql',
      'iam.inspect_invitation_token':
          '20260911005_iam_hybrid_owner_accept_decline_unwind.sql',
      'iam.get_tenant_readiness': '20260811016_iam_tenant_readiness_activate.sql',
      'iam.bootstrap_owner': '20260914001_iam_get_session_context_multi_tenant.sql',
      'iam.get_session_context':
          '20260914001_iam_get_session_context_multi_tenant.sql',
    };
    String body(String fn) => _lastFunctionBlock(_readMigration(owners[fn]!), fn);

    test('rewritten per rules', () => _expectRewritten(owners));

    test('membership inserts no longer write status', () {
      for (final fn in [
        'iam.accept_invitation',
        'iam.create_tenant_invitation',
        'iam.create_tenant_onboarding',
        'iam.reinvite_provisioning_owner',
      ]) {
        expect(
          body(fn),
          contains(
            'tenant_id, user_id, role, is_owner, version, created_at, updated_at',
          ),
          reason: fn,
        );
      }
      expect(
        body('iam.create_tenant_invitation'),
        isNot(
          contains(
            "coalesce(v_role.code, 'staff'),\n    'active',",
          ),
        ),
      );
    });

    test('create invitation detects existing membership by removed_at', () {
      final b = body('iam.create_tenant_invitation');
      expect(b, contains('and m.removed_at is null'));
      expect(b, contains('if v_existing_membership.is_active then'));
    });

    test('inspect keeps owner initial_role_id output value', () {
      expect(
        body('iam.inspect_invitation_token'),
        contains("'initial_role_id', case when v_should_be_owner then 'owner'"),
      );
    });
  });

  group('tenant and member read rpcs (final definitions)', () {
    const owners = {
      'iam.activate_tenant':
          '20260916007_iam_patch_activate_tenant_default_store_scope.sql',
      'iam.update_tenant_profile':
          '20260826002_iam_tenant_audit_history_v2_payloads.sql',
      'iam.get_platform_tenant':
          '20260911003_iam_get_platform_tenant_owner_from_invitation.sql',
      'iam.search_platform_tenants': '20260811010_iam_platform_tenants_read.sql',
      'iam.list_accessible_tenants':
          '20260811014_iam_tenant_membership_lifecycle.sql',
      'iam.list_user_tenants': '20260811014_iam_tenant_membership_lifecycle.sql',
      'iam.list_platform_tenant_members':
          '20260811010_iam_platform_tenants_read.sql',
      'iam.list_tenant_members':
          '20260820004_iam_tenant_member_detail_user_info.sql',
    };

    test('rewritten per rules', () => _expectRewritten(owners));

    test('list_tenant_members filters and outputs derived status', () {
      final b = _lastFunctionBlock(
        _readMigration(owners['iam.list_tenant_members']!),
        'iam.list_tenant_members',
      );
      expect(
        b,
        contains('iam._membership_status_code(m.is_active, m.removed_at) as status,'),
      );
      expect(
        b,
        contains(
          'and (v_status is null or iam._membership_status_code(m.is_active, m.removed_at) = v_status)',
        ),
      );
    });
  });

  group('misc read rpcs (final definitions)', () {
    const owners = {
      'iam.get_tenant_member':
          '20260820004_iam_tenant_member_detail_user_info.sql',
      'iam.get_tenant_invitation': '20260826001_iam_fix_utc_now_offset.sql',
      'iam.list_tenant_invitations': '20260826001_iam_fix_utc_now_offset.sql',
      'iam.list_assignable_invitation_roles':
          '20260811024_iam_patch_owner_role_canonicalization.sql',
      'iam.get_tenant_audit_log': '20260826004_iam_audit_logs_v2_rebuild.sql',
      'iam.search_tenant_audit_logs_v2':
          '20260826004_iam_audit_logs_v2_rebuild.sql',
    };

    test('rewritten per rules', () => _expectRewritten(owners));
  });
}

/// Membership `status` column reads that must disappear from final RPC bodies.
final RegExp _legacyMembershipStatus = RegExp(
  r'\b(m|om|membership|p_membership|v_row|v_target_row|v_existing_membership|v_membership)\.status\b',
);

/// Legacy role checks (role `owner` no longer exists).
final RegExp _ownerRoleLiteral = RegExp(
  r"role\s*=\s*'owner'|\('owner',\s*'store_owner'\)",
);

void _expectRewritten(Map<String, String> ownerByFunction) {
  for (final entry in ownerByFunction.entries) {
    final body = _lastFunctionBlock(_readMigration(entry.value), entry.key);
    expect(body, isNot(matches(_legacyMembershipStatus)), reason: entry.key);
    expect(body, isNot(matches(_ownerRoleLiteral)), reason: entry.key);
    expect(
      body,
      isNot(matches(RegExp(r'\bstatus,\s*is_owner'))),
      reason: entry.key,
    );
  }
}

String _readMigration(String fileName) {
  final root = _findRepoRoot();
  return File('${root.path}/supabase/migrations/$fileName').readAsStringSync();
}

/// Last `create or replace function <qualifiedName>(` … `$$;` in [sql].
String _lastFunctionBlock(String sql, String qualifiedName) {
  final start = sql.lastIndexOf('create or replace function $qualifiedName(');
  if (start < 0) {
    throw StateError('$qualifiedName not found in migration');
  }
  final end = sql.indexOf(r'$$;', start);
  if (end < 0) {
    throw StateError('end of $qualifiedName not found');
  }
  return sql.substring(start, end + 3);
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
