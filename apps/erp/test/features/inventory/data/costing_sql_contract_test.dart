import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Directory _findRepoRoot() {
  var dir = Directory.current.absolute;
  while (true) {
    final candidate = File(
      '${dir.path}/supabase/migrations/20261110001_inventory_core.sql',
    );
    if (candidate.existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError(
        'Cannot find repo root from ${Directory.current.path}',
      );
    }
    dir = parent;
  }
}

void main() {
  late String costingSql;
  late String salesLinkSql;

  setUpAll(() {
    final root = _findRepoRoot();
    final costingFile = File(
      '${root.path}/supabase/migrations/20261118001_inventory_costing.sql',
    );
    costingSql = costingFile.existsSync() ? costingFile.readAsStringSync() : '';
    salesLinkSql = File(
      '${root.path}/supabase/migrations/20261115001_inventory_sales_link.sql',
    ).readAsStringSync();
  });

  String fnSection(String sql, String fnName) {
    final marker = 'create or replace function inventory.$fnName(';
    final start = sql.indexOf(marker);
    expect(start, greaterThanOrEqualTo(0), reason: 'Missing $marker');
    final nextFn = sql.indexOf(
      'create or replace function inventory.',
      start + marker.length,
    );
    return nextFn > start ? sql.substring(start, nextFn) : sql.substring(start);
  }

  test('task1_tables_rls_and_partial_unique', () {
    for (final table in [
      'inventory.cost_runs',
      'inventory.cost_run_lines',
    ]) {
      expect(
        costingSql,
        contains('alter table $table enable row level security;'),
      );
      expect(
        costingSql,
        contains('revoke all on $table from public, anon, authenticated;'),
      );
    }
    expect(
      costingSql,
      contains("where status = 'READY_FOR_REVIEW'"),
    );
  });

  test('task1_five_functions_security_and_grants', () {
    final internals = <String, String>{
      '_cost_run_compute': 'uuid, bigint, bigint, text',
      '_cost_run_is_stale': 'uuid, inventory.cost_runs',
      '_cost_run_view': 'uuid, uuid',
    };
    for (final entry in internals.entries) {
      final sec = fnSection(costingSql, entry.key);
      expect(sec, contains('security definer'));
      expect(
        sec,
        contains(
          'revoke all on function inventory.${entry.key}(${entry.value}) from public, anon, authenticated;',
        ),
      );
      expect(
        sec,
        isNot(
          contains(
            'grant execute on function inventory.${entry.key}(${entry.value}) to authenticated;',
          ),
        ),
      );
    }

    final rpcs = <String, String>{
      'create_cost_run': 'uuid, text, text',
      'get_cost_run': 'uuid, uuid',
    };
    for (final entry in rpcs.entries) {
      final sec = fnSection(costingSql, entry.key);
      expect(sec, contains('security definer'));
      expect(
        sec,
        contains(
          'grant execute on function inventory.${entry.key}(${entry.value}) to authenticated;',
        ),
      );
      final assertIdx = sec.indexOf(
        "inventory._assert_actor(p_tenant_id, 'inventory.read', true)",
      );
      expect(assertIdx, greaterThan(0), reason: '${entry.key} missing _assert_actor');
      final selectIdx = sec.indexOf('select ');
      if (selectIdx > 0) {
        expect(
          assertIdx,
          lessThan(selectIdx),
          reason: '${entry.key}: _assert_actor must come before first select',
        );
      }
    }
  });

  test('create_cost_run_locks_ledger_counters_and_has_6_blockers', () {
    final sec = fnSection(costingSql, 'create_cost_run');
    final lockIdx = sec.indexOf('from inventory.ledger_counters');
    expect(lockIdx, greaterThan(0));
    expect(sec.substring(lockIdx), contains('for update'));
    final computeIdx = sec.indexOf('inventory._cost_run_compute');
    expect(computeIdx, greaterThan(lockIdx));

    for (final code in [
      'PREVIOUS_PERIOD_OPEN',
      'PERIOD_NOT_ENDED',
      'STOCKTAKE_OPEN',
      'RUN_PENDING_REVIEW',
      'NOTHING_TO_COST',
      'LEDGER_MISMATCH',
    ]) {
      expect(sec, contains("'$code'"));
    }
  });

  test('task2_five_rpcs_security_grants_and_actor_assert', () {
    final rpcs = <String, String>{
      'get_cost_overview': 'uuid',
      'set_cost_policy': 'uuid, text, text',
      'publish_cost_run': 'uuid, uuid, text',
      'discard_cost_run': 'uuid, uuid, text',
      'list_cost_versions': 'uuid, uuid',
    };
    for (final entry in rpcs.entries) {
      final sec = fnSection(costingSql, entry.key);
      expect(sec, contains('security definer'));
      expect(
        sec,
        contains(
          'grant execute on function inventory.${entry.key}(${entry.value}) to authenticated;',
        ),
      );
      final assertIdx = sec.indexOf(
        "inventory._assert_actor(p_tenant_id, 'inventory.read', true)",
      );
      expect(assertIdx, greaterThan(0), reason: '${entry.key} missing _assert_actor');
      final selectIdx = sec.indexOf('select ');
      if (selectIdx > 0) {
        expect(
          assertIdx,
          lessThan(selectIdx),
          reason: '${entry.key}: _assert_actor must come before first select',
        );
      }
    }
  });

  test('task2_locks_error_codes_and_reversal_kind', () {
    for (final fn in ['publish_cost_run', 'discard_cost_run']) {
      final sec = fnSection(costingSql, fn);
      final lockIdx = sec.indexOf("hashtext('cost')");
      final forUpdateIdx = sec.indexOf('for update');
      expect(lockIdx, greaterThan(0), reason: '$fn missing cost lock');
      expect(forUpdateIdx, greaterThan(lockIdx), reason: '$fn: cost lock must precede for update');
    }

    final pubSec = fnSection(costingSql, 'publish_cost_run');
    expect(pubSec, contains('v_lock_product_id uuid'));
    expect(pubSec, contains('order by crl.product_id'));
    expect(pubSec, contains('hashtext(v_lock_product_id::text)'));
    expect(
      RegExp(r'for\s+v_line\s+in\s+select\s+crl\.product_id').hasMatch(pubSec),
      isFalse,
      reason: 'must not assign single column into inventory.cost_run_lines row variable',
    );
    final firstProductLock = pubSec.indexOf('hashtext(v_lock_product_id::text)');
    final firstAdjust = pubSec.indexOf('_post_value_adjustment');
    expect(firstProductLock, greaterThan(0));
    expect(firstAdjust, greaterThan(firstProductLock));
    expect(
      pubSec.indexOf('pg_advisory_xact_lock', firstAdjust),
      equals(-1),
      reason: 'publish_cost_run must acquire all advisory locks before posting adjustments',
    );

    final createSec = fnSection(costingSql, 'create_cost_run');
    expect(createSec, contains("'pending_run_id'"));

    for (final code in [
      'COST_RUN_STALE',
      'COST_RUN_NOT_READY',
      'COST_POLICY_LOCKED',
    ]) {
      expect(costingSql, contains("'$code'"));
    }

    final revSec = fnSection(salesLinkSql, '_reversal_kind');
    expect(revSec, contains('inventory.cost_runs'));
  });
}

