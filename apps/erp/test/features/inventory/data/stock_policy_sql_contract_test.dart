import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String sql;

  setUpAll(() {
    final repoRoot = _findRepoRoot();
    final file = File(
      '${repoRoot.path}/supabase/migrations/20261111001_inventory_stock_policy.sql',
    );
    expect(file.existsSync(), isTrue, reason: 'Migration file must exist');
    sql = file.readAsStringSync();
  });

  group('inventory_stock_policy SQL contract', () {
    test('stock_policy_tables_have_rls_and_revoke', () {
      for (final t in ['stock_policy_settings', 'product_stock_policies']) {
        expect(
          sql,
          contains('alter table inventory.$t enable row level security'),
        );
        expect(
          sql,
          contains('revoke all on inventory.$t from public, anon, authenticated'),
        );
      }
    });

    test('helpers_are_revoked', () {
      for (final f in [
        '_today()',
        '_lot_expiry_end(date, text)',
        '_near_expiry_days(uuid, uuid)',
        '_product_stock_rows(uuid)',
      ]) {
        expect(
          sql,
          contains('revoke all on function inventory.$f from public, anon, authenticated'),
        );
      }
    });

    test('rpcs_security_definer_and_granted', () {
      for (final f in [
        'get_stock_policy(uuid)',
        'save_stock_thresholds(uuid, text, int, jsonb)',
        'save_near_expiry_policy(uuid, text, int, int, jsonb)',
      ]) {
        expect(
          sql,
          contains('grant execute on function inventory.$f to authenticated'),
        );
      }
      expect(
        RegExp('security definer').allMatches(sql).length,
        greaterThanOrEqualTo(7),
      );
    });

    test('save_rpcs_require_owner_and_check_revision', () {
      expect(
        RegExp(r"_assert_actor\(p_tenant_id, 'inventory\.stock_policy\.manage', true\)").allMatches(sql).length,
        2,
      );
      expect(
        RegExp(r"_raise\('VERSION_CONFLICT'").allMatches(sql).length,
        2,
      );
      expect(sql, contains("'stock_policy.thresholds'"));
      expect(sql, contains("'stock_policy.near_expiry'"));
    });

    test('no_new_error_codes', () {
      final codes = RegExp(r"_raise\('([A-Z_]+)'")
          .allMatches(sql)
          .map((m) => m[1])
          .toSet();
      expect(
        codes.difference({
          'PERMISSION_DENIED',
          'CONTEXT_INVALID',
          'VERSION_CONFLICT',
          'IDEMPOTENCY_CONFLICT',
          'COMMAND_IN_PROGRESS',
        }),
        isEmpty,
      );
    });
  });
}

Directory _findRepoRoot() {
  var current = Directory.current.absolute;
  while (!Directory('${current.path}/supabase/migrations').existsSync()) {
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not locate workspace root');
    }
    current = parent;
  }
  return current;
}

