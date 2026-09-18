import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — IAM refactor bảng 1 `iam.tenants`
/// (docs/superpowers/specs/iam-schema-refactor/01-tenants.md).
void main() {
  group('tenants DDL in original migrations', () {
    test('foundation creates display_name instead of name', () {
      final sql = _readMigration('20260630000001_iam_foundation.sql');
      final table = sql.substring(
        sql.indexOf('create table if not exists iam.tenants ('),
        sql.indexOf(');', sql.indexOf('create table if not exists iam.tenants (')),
      );
      expect(table, contains('display_name text not null,'));
      // Avoid substring false-positive inside `display_name text not null`.
      expect(table, isNot(contains(RegExp(r'(?<![a-z_])name text not null'))));
    });

    test('platform tenants read no longer adds legacy columns', () {
      final sql = _readMigration('20260811010_iam_platform_tenants_read.sql');
      for (final column in const [
        'code',
        'suspended_at',
        'suspend_reason',
        'suspended_by',
        'closed_at',
        'close_reason',
        'closed_by',
      ]) {
        expect(sql, isNot(contains('add column if not exists $column ')), reason: column);
      }
    });

    test('tenant profile adds shared status columns, no created_by_user_id, no name backfill', () {
      final sql = _readMigration('20260811015_iam_tenant_profile_legal.sql');
      expect(sql, contains('add column if not exists status_changed_by uuid,'));
      expect(sql, contains('add column if not exists status_reason text,'));
      expect(sql, isNot(contains('created_by_user_id')));
      expect(sql, isNot(contains('coalesce(display_name, name)')));
    });
  });

  group('tenant write rpcs (final definitions)', () {
    const owners = {
      'iam.create_tenant_onboarding': '20260916004_iam_patch_onboarding_default_store_scope.sql',
      'iam.update_tenant_profile': '20260826002_iam_tenant_audit_history_v2_payloads.sql',
      'iam.activate_tenant': '20260916007_iam_patch_activate_tenant_default_store_scope.sql',
      'iam.suspend_platform_tenant': '20260811011_iam_platform_tenant_lifecycle.sql',
      'iam.restore_platform_tenant': '20260811011_iam_platform_tenant_lifecycle.sql',
    };

    String body(String fn) => _lastFunctionBlock(_readMigration(owners[fn]!), fn);

    test('no legacy tenant columns', () {
      for (final fn in owners.keys) {
        expect(body(fn), isNot(matches(_legacyTenantColumnRef)), reason: fn);
        expect(body(fn), isNot(contains('suspended_at')), reason: fn);
        expect(body(fn), isNot(contains('suspended_by')), reason: fn);
      }
    });

    test('onboarding inserts display_name and status columns', () {
      final b = body('iam.create_tenant_onboarding');
      expect(b, contains('insert into iam.tenants (\n    display_name,'));
      expect(b, contains('status_changed_at, status_changed_by, updated_at'));
    });

    test('update profile derives code and no longer mirrors name', () {
      final b = body('iam.update_tenant_profile');
      expect(
        b,
        isNot(matches(RegExp(r'^\s*name = p_display_name', multiLine: true))),
      );
      expect(b, contains('left(v_row.id::text, 8)'));
    });

    test('activate / suspend / restore write shared status columns', () {
      expect(body('iam.activate_tenant'), contains('status_changed_by = auth.uid()'));
      expect(body('iam.suspend_platform_tenant'), contains('status_reason = trim(p_reason)'));
      expect(body('iam.restore_platform_tenant'), contains('status_reason = null'));
      expect(body('iam.restore_platform_tenant'), contains('status_changed_by = v_actor'));
    });
  });

  group('tenant read/context rpcs (final definitions)', () {
    const owners = {
      'iam._tenant_json': '20260811015_iam_tenant_profile_legal.sql',
      'iam.get_platform_tenant': '20260911003_iam_get_platform_tenant_owner_from_invitation.sql',
      'iam.search_platform_tenants': '20260811010_iam_platform_tenants_read.sql',
      'iam.list_user_tenants': '20260811014_iam_tenant_membership_lifecycle.sql',
      'iam.list_accessible_tenants': '20260811014_iam_tenant_membership_lifecycle.sql',
      'iam.get_tenant_context': '20260811024_iam_patch_owner_role_canonicalization.sql',
      'iam.switch_tenant_context': '20260811024_iam_patch_owner_role_canonicalization.sql',
      'iam._ensure_tenant_default_store': '20260916001_iam_ensure_default_store_scope_helpers.sql',
    };

    String body(String fn) => _lastFunctionBlock(_readMigration(owners[fn]!), fn);

    test('no legacy tenant columns', () {
      for (final fn in owners.keys) {
        expect(body(fn), isNot(matches(_legacyTenantColumnRef)), reason: fn);
      }
    });

    test('get_platform_tenant derives legacy keys', () {
      final b = body('iam.get_platform_tenant');
      expect(b, contains("'name', v_tenant.display_name"));
      expect(b, contains("'code', left(v_tenant.id::text, 8)"));
      expect(
        b,
        contains(
          "'suspended_at', case when v_tenant.status = 'suspended' "
          'then v_tenant.status_changed_at end',
        ),
      );
      expect(
        b,
        contains(
          "'close_reason', case when v_tenant.status = 'closed' "
          'then v_tenant.status_reason end',
        ),
      );
    });

    test('search keeps name/code output columns', () {
      final b = body('iam.search_platform_tenants');
      expect(b, contains('t.display_name::text as name'));
      expect(b, contains('left(t.id::text, 8)::text as code'));
    });
  });

  group('tenant name/code consumers (final definitions)', () {
    const owners = {
      'iam.accept_invitation': '20260916006_iam_patch_accept_invitation_default_store_scope.sql',
      'iam.inspect_invitation_token': '20260911005_iam_hybrid_owner_accept_decline_unwind.sql',
      'iam.get_platform_user': '20260911002_iam_patch_search_phone_status_casts.sql',
      'iam.get_tenant_readiness': '20260811016_iam_tenant_readiness_activate.sql',
      'iam.get_platform_audit_log': '20260826004_iam_audit_logs_v2_rebuild.sql',
      'iam.search_tenant_audit_logs_v2': '20260826004_iam_audit_logs_v2_rebuild.sql',
      'iam.get_tenant_audit_log': '20260826004_iam_audit_logs_v2_rebuild.sql',
      'iam.search_platform_audit_logs': '20260826004_iam_audit_logs_v2_rebuild.sql',
    };

    test('no legacy tenant columns', () {
      for (final entry in owners.entries) {
        expect(
          _lastFunctionBlock(_readMigration(entry.value), entry.key),
          isNot(matches(_legacyTenantColumnRef)),
          reason: entry.key,
        );
      }
    });

    test('accept_invitation derives tenant code from id', () {
      final b = _lastFunctionBlock(
        _readMigration(owners['iam.accept_invitation']!),
        'iam.accept_invitation',
      );
      expect('left(v_tenant.id::text, 8)'.allMatches(b).length, 6);
    });
  });
}

/// Column refs on tenant variables that must disappear from final RPC bodies.
final RegExp _legacyTenantColumnRef = RegExp(
  r'\b(t|v_tenant|p_tenant|v_row)\.(name|code|suspended_at|suspend_reason|'
  r'suspended_by|closed_at|close_reason|closed_by|created_by_user_id)\b',
);

String _readMigration(String fileName) {
  final root = _findRepoRoot();
  return File('${root.path}/supabase/migrations/$fileName').readAsStringSync();
}

/// Last `create or replace function <qualifiedName>(` … `$$;` in [sql].
String _lastFunctionBlock(String sql, String qualifiedName) {
  final start = sql.lastIndexOf('create or replace function $qualifiedName(');
  if (start < 0) {
    throw StateError('$qualifiedName not found');
  }
  final end = sql.indexOf(r'$$;', start);
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
