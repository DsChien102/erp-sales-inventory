import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String sql;

  setUpAll(() {
    final root = _findRepoRoot();
    sql = File(
      '${root.path}/supabase/migrations/_drafts/016_iam_tenant_readiness_activate.sql',
    ).readAsStringSync();
  });

  group('get_tenant_readiness blockers', () {
    test('emits each profile blocker code', () {
      for (final code in const [
        'TENANT_DISPLAY_NAME_MISSING',
        'TENANT_CONTACT_EMAIL_MISSING_OR_INVALID',
        'TENANT_CONTACT_PHONE_MISSING_OR_INVALID',
        'TENANT_CONTACT_ADDRESS_MISSING',
        'OWNER_MEMBERSHIP_INVALID',
      ]) {
        expect(sql, contains(code), reason: 'missing blocker $code');
      }
    });

    test('owner identity uses Auth-derived activation and Auth snapshot', () {
      expect(sql, contains('iam.get_auth_user_snapshot(v_owner_user)'));
      expect(
        sql,
        contains('iam._platform_user_effective_status(u.email_confirmed_at)'),
      );
      expect(sql, isNot(contains('from iam.platform_user_profiles p')));
      expect(sql, isNot(contains('select p.status')));
      expect(sql, contains('OWNER_IDENTITY_INACTIVE'));
      expect(sql, contains('OWNER_IDENTITY_UNAVAILABLE'));
      expect(sql, contains('OWNER_EMAIL_UNVERIFIED'));
    });

    test('missing legal profile and duplicate tax are warnings only', () {
      expect(sql, contains("v_warnings := v_warnings || to_jsonb('LEGAL_PROFILE_MISSING'::text)"));
      expect(sql, contains("v_warnings := v_warnings || to_jsonb('DUPLICATE_TAX_CODE'::text)"));
      // They must never be pushed into the blockers array.
      expect(sql, isNot(contains("v_blockers := v_blockers || to_jsonb('LEGAL_PROFILE_MISSING")));
      expect(sql, isNot(contains("v_blockers := v_blockers || to_jsonb('DUPLICATE_TAX_CODE")));
    });
  });

  group('activate_tenant transaction', () {
    test('same key + different payload raises IDEMPOTENCY_CONFLICT', () {
      expect(sql, contains('v_existing.payload_hash <> v_payload_hash'));
      expect(sql, contains("raise exception 'IDEMPOTENCY_CONFLICT'"));
    });

    test('locks tenant and active owner membership for update', () {
      expect(sql, contains('from iam.tenants t where t.id = p_tenant_id for update'));
      expect(sql, contains('for update'));
      expect(sql, contains("(m.is_owner is true or m.role = 'owner')"));
      expect(
        sql,
        isNot(contains("coalesce(m.is_owner, m.role = 'owner')")),
      );
    });

    test('re-evaluates readiness inside the transaction', () {
      expect(sql, contains('v_readiness := iam.get_tenant_readiness(p_tenant_id)'));
      expect(sql, contains("raise exception 'READINESS_BLOCKED'"));
    });

    test('enqueues iam.tenant.activated outbox message', () {
      expect(sql, contains('iam.enqueue_outbox_message('));
      expect(sql, contains("'iam.tenant.activated'"));
    });

    test('optimistic concurrency guard on version', () {
      expect(sql, contains('v_tenant.version <> p_expected_version'));
      expect(sql, contains("raise exception 'STATE_CHANGED'"));
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
