import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — IAM refactor 01b close tenant
/// (docs/superpowers/specs/iam-schema-refactor/01-tenants.md §5).
void main() {
  final root = _findRepoRoot().path;
  String readMigration(String name) => File('$root/supabase/migrations/$name').readAsStringSync();

  String lastFunctionBlock(String sql, String qualifiedName) {
    final start = sql.lastIndexOf('create or replace function $qualifiedName(');
    if (start < 0) {
      throw StateError('$qualifiedName not found');
    }
    final bodyStart = sql.indexOf(r'as $$', start);
    final end = sql.indexOf(r'$$;', bodyStart + 5);
    return sql.substring(start, end);
  }

  group('close_platform_tenant', () {
    final sql = readMigration('20260811011_iam_platform_tenant_lifecycle.sql');
    String body() => lastFunctionBlock(sql, 'iam.close_platform_tenant');

    test('header touches the new function', () {
      expect(
        sql,
        contains(
          '-- Touches: iam.suspend_platform_tenant, iam.restore_platform_tenant, iam.close_platform_tenant',
        ),
      );
    });

    test('signature, permission and grants', () {
      final b = body();
      expect(b, contains('p_tenant_id uuid,'));
      expect(b, contains('p_reason text,'));
      expect(b, contains('p_expected_version integer,'));
      expect(b, contains('p_idempotency_key text'));
      expect(
        b,
        contains("iam.has_platform_permission('platform.tenant.close')"),
      );
      expect(
        sql,
        contains(
          'revoke all on function iam.close_platform_tenant(uuid, text, integer, text) from public, anon;',
        ),
      );
      expect(
        sql,
        contains(
          'grant execute on function iam.close_platform_tenant(uuid, text, integer, text) to authenticated;',
        ),
      );
    });

    test('reason and idempotency key are required', () {
      final b = body();
      expect(b, contains("if p_reason is null or trim(p_reason) = '' then"));
      expect(
        b,
        contains("if p_idempotency_key is null or trim(p_idempotency_key) = '' then"),
      );
    });

    test('only active or suspended can be closed', () {
      final b = body();
      expect(b, contains("if v_status not in ('active', 'suspended') then"));
      expect(b, contains("raise exception 'TENANT_STATE_INVALID'"));
    });

    test('replay with same key after close returns without side effects', () {
      final b = body();
      expect(b, contains("event_code = 'iam.tenant.closed'"));
      expect(b, contains('tracking_id = trim(p_idempotency_key)'));
    });

    test('writes shared status columns, not legacy closed_* columns', () {
      final b = body();
      expect(b, contains("set status = 'closed'"));
      expect(b, contains('status_changed_at = now()'));
      expect(b, contains('status_changed_by = v_actor'));
      expect(b, contains('status_reason = trim(p_reason)'));
      expect(b, contains('version = version + 1'));
      expect(
        b,
        isNot(matches(RegExp(r'\b(closed_at|close_reason|closed_by)\b'))),
      );
    });

    test('does not touch memberships, invitations or stores', () {
      final b = body();
      expect(b, isNot(contains('iam.memberships')));
      expect(b, isNot(contains('iam.tenant_invitations')));
      expect(b, isNot(contains('iam.stores')));
    });

    test('appends iam.tenant.closed audit with reason', () {
      final b = body();
      expect(b, contains("p_event_code => 'iam.tenant.closed'"));
      expect(b, contains("'reason', trim(p_reason)"));
    });
  });

  test('audit category registers iam.tenant.closed as organization', () {
    final sql = readMigration('20260826004_iam_audit_logs_v2_rebuild.sql');
    final body = lastFunctionBlock(sql, 'iam._audit_event_category');
    expect(
      body,
      contains("'iam.tenant.restored',\n         'iam.tenant.closed',"),
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
