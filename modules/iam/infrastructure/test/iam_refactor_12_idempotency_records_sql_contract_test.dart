import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — IAM refactor bảng 12: unified idempotency store
/// (docs/superpowers/specs/iam-schema-refactor/12-idempotency-records.md).
void main() {
  group('idempotency_records DDL', () {
    final lifecycle = _readMigration('20260811005_iam_platform_user_lifecycle.sql');

    test('table and helpers live in 20260811005', () {
      expect(lifecycle, contains('create table if not exists iam.idempotency_records ('));
      expect(lifecycle, contains('primary key (operation, scope_id, idempotency_key)'));
      final find = _lastFunctionBlock(lifecycle, 'iam._idempotency_find');
      expect(find, contains('v_row.payload_hash is distinct from p_payload_hash'));
      expect(find, contains("raise exception 'IDEMPOTENCY_CONFLICT';"));
      expect(_lastFunctionBlock(lifecycle, 'iam._idempotency_store'), contains('insert into iam.idempotency_records'));
      expect(
        lifecycle,
        contains(
          'revoke all on function iam._idempotency_find(text, text, text, text) from public, anon, authenticated;',
        ),
      );
      expect(
        lifecycle,
        contains(
          'revoke all on function iam._idempotency_store(text, text, text, text, jsonb) from public, anon, authenticated;',
        ),
      );
    });

    test('no migration creates or alters legacy idempotency tables', () {
      final dir = Directory('${_findRepoRoot().path}/supabase/migrations');
      for (final file in dir.listSync().whereType<File>().where((f) => f.path.endsWith('.sql'))) {
        final sql = file.readAsStringSync();
        for (final table in _legacyTables) {
          expect(sql, isNot(contains('create table if not exists iam.$table')), reason: '${file.path} $table');
          expect(sql, isNot(contains('alter table iam.$table')), reason: '${file.path} $table');
          expect(sql, isNot(contains('revoke all on table iam.$table')), reason: '${file.path} $table');
        }
      }
    });

    test('dead onboarding operation rpcs removed', () {
      final onboarding = _readMigration('20260811006_iam_create_tenant_onboarding.sql');
      expect(onboarding, isNot(contains('get_tenant_onboarding_operation')));
      expect(onboarding, isNot(contains('retry_tenant_onboarding_operation')));
    });
  });

  group('onboarding/invitation idempotency', () {
    test(
      'uses idempotency_records',
      () => _expectUsesIdempotencyRecords(const {
        'iam.create_tenant_onboarding': (
          '20260916004_iam_patch_onboarding_default_store_scope.sql',
          'tenant.onboard',
        ),
        'iam.create_tenant_invitation': (
          '20260916005_iam_patch_invitation_membership_store_scope.sql',
          'tenant.invitation.create',
        ),
        'iam.resend_tenant_invitation': (
          '20260826002_iam_tenant_audit_history_v2_payloads.sql',
          'tenant.invitation.resend',
        ),
        'iam.revoke_tenant_invitation': (
          '20260916005_iam_patch_invitation_membership_store_scope.sql',
          'tenant.invitation.revoke',
        ),
        'iam.accept_invitation': (
          '20260916006_iam_patch_accept_invitation_default_store_scope.sql',
          'tenant.invitation.accept',
        ),
        'iam.decline_invitation': (
          '20260916005_iam_patch_invitation_membership_store_scope.sql',
          'tenant.invitation.decline',
        ),
      }),
    );
  });

  group('platform idempotency', () {
    test(
      'uses idempotency_records',
      () => _expectUsesIdempotencyRecords(const {
        'iam.activate_tenant': (
          '20260916007_iam_patch_activate_tenant_default_store_scope.sql',
          'tenant.activate',
        ),
        'iam.transfer_platform_tenant_ownership': (
          '20260811012_iam_platform_transfer_ownership.sql',
          'tenant.ownership.transfer',
        ),
        'iam.suspend_platform_user': (
          '20260820002_iam_platform_user_suspend_state_changed_fix.sql',
          'platform_user.suspend',
        ),
        'iam.reinvite_provisioning_owner': (
          '20260911006_iam_reinvite_provisioning_owner.sql',
          'tenant.owner.reinvite',
        ),
      }),
    );
  });
}

const _legacyTables = [
  'onboarding_operations',
  'tenant_invitation_operations',
  'tenant_invitation_mutate_operations',
  'tenant_invitation_token_operations',
  'tenant_activation_operations',
  'ownership_transfer_operations',
  'platform_user_lifecycle_operations',
  'provisioning_owner_reinvite_operations',
];

void _expectUsesIdempotencyRecords(Map<String, (String, String)> byFunction) {
  for (final entry in byFunction.entries) {
    final (file, operation) = entry.value;
    final body = _lastFunctionBlock(_readMigration(file), entry.key);
    for (final table in _legacyTables) {
      expect(body, isNot(contains('iam.$table')), reason: '${entry.key} → $table');
    }
    expect(body, contains("iam._idempotency_find('$operation',"), reason: entry.key);
    expect(body, contains("iam._idempotency_store('$operation',"), reason: entry.key);
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
