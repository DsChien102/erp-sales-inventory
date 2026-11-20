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
  late String stocktakeSql;
  late String coreSql;

  setUpAll(() {
    final root = _findRepoRoot();
    stocktakeSql = File(
      '${root.path}/supabase/migrations/20261116001_inventory_stocktake.sql',
    ).readAsStringSync();
    coreSql = File(
      '${root.path}/supabase/migrations/20261110001_inventory_core.sql',
    ).readAsStringSync();
  });

  test('tables_rls_revoked: all 3 stocktake tables enable RLS and revoke access', () {
    for (final table in [
      'inventory.stocktake_sessions',
      'inventory.stocktake_lines',
      'inventory.stocktake_counts',
    ]) {
      expect(
        stocktakeSql,
        contains('alter table $table enable row level security;'),
        reason: 'Missing RLS on $table',
      );
      expect(
        stocktakeSql,
        contains(
          'revoke all on $table from public, anon, authenticated;',
        ),
        reason: 'Missing revoke all on $table',
      );
    }
  });

  test('counts_append_only: stocktake_counts forbids UPDATE and DELETE via trigger', () {
    expect(
      stocktakeSql,
      contains('on inventory.stocktake_counts'),
    );
    expect(
      stocktakeSql,
      contains('before update or delete'),
    );
    expect(
      stocktakeSql,
      contains('inventory._forbid_ledger_mutation()'),
    );
  });

  test('public_rpcs_granted: Task 1 public RPCs use security definer, assert actor, and grant execute', () {
    final rpcs = <String, String>{
      'list_stocktake_sessions': 'uuid',
      'get_stocktake_form_options': 'uuid',
      'open_stocktake': 'uuid, text, jsonb',
      'get_stocktake_session': 'uuid, uuid',
      'save_stocktake_draft': 'uuid, uuid, uuid, numeric',
      'get_stocktake_unexpected_options': 'uuid, uuid',
      'add_stocktake_unexpected_line': 'uuid, uuid, jsonb',
      'cancel_stocktake': 'uuid, text, uuid, text',
    };

    for (final entry in rpcs.entries) {
      final name = entry.key;
      final sig = entry.value;
      expect(
        stocktakeSql,
        contains('create or replace function inventory.$name('),
        reason: 'Missing function inventory.$name',
      );
      expect(
        stocktakeSql,
        contains('grant execute on function inventory.$name($sig) to authenticated;'),
        reason: 'Missing grant execute for inventory.$name($sig)',
      );
    }

    expect(
      stocktakeSql,
      contains('security definer'),
    );
    expect(
      stocktakeSql,
      contains("inventory._assert_actor(p_tenant_id, 'inventory.read')"),
    );
  });

  test('has_open_not_granted: _has_open_stocktake is internal helper only', () {
    expect(
      stocktakeSql,
      contains('create or replace function inventory._has_open_stocktake('),
    );
    expect(
      stocktakeSql,
      contains(
        'revoke all on function inventory._has_open_stocktake(uuid) from public, anon, authenticated;',
      ),
    );
    expect(
      stocktakeSql,
      isNot(
        contains(
          'grant execute on function inventory._has_open_stocktake(uuid) to authenticated;',
        ),
      ),
    );
  });

  test('open_uses_idempotency: open_stocktake uses _begin_idempotency and _complete_idempotency', () {
    final start = stocktakeSql.indexOf(
      'create or replace function inventory.open_stocktake(',
    );
    expect(start, greaterThanOrEqualTo(0));
    final nextFn = stocktakeSql.indexOf(
      'create or replace function inventory.',
      start + 1,
    );
    final body = nextFn > start
        ? stocktakeSql.substring(start, nextFn)
        : stocktakeSql.substring(start);

    expect(body, contains('inventory._begin_idempotency('));
    expect(body, contains("'stocktake.open'"));
    expect(body, contains('inventory._complete_idempotency('));
  });

  test('hub_counts_stocktakes: get_warehouse_hub_summary counts open stocktakes', () {
    final start = coreSql.indexOf(
      'create or replace function inventory.get_warehouse_hub_summary(',
    );
    expect(start, greaterThanOrEqualTo(0));
    final end = coreSql.indexOf('grant execute on function inventory.get_warehouse_hub_summary', start);
    expect(end, greaterThan(start));
    final body = coreSql.substring(start, end);

    expect(body, contains('stocktake_sessions'));
    expect(body, contains("'stocktakes_open'"));
  });

  String fnSection(String fnName) {
    final marker = 'create or replace function inventory.$fnName(';
    final start = stocktakeSql.indexOf(marker);
    expect(start, greaterThanOrEqualTo(0), reason: 'Missing $marker');
    final nextFn = stocktakeSql.indexOf(
      'create or replace function inventory.',
      start + marker.length,
    );
    return nextFn > start
        ? stocktakeSql.substring(start, nextFn)
        : stocktakeSql.substring(start);
  }

  test('submits_granted: submit RPCs are granted and use stocktake idempotency scopes', () {
    for (final entry in <String, String>{
      'submit_stocktake_first_count': 'stocktake.first',
      'submit_stocktake_recount': 'stocktake.recount',
    }.entries) {
      final body = fnSection(entry.key);
      expect(body, contains('security definer'));
      expect(body, contains("inventory._assert_actor(p_tenant_id, 'inventory.read')"));
      expect(body, contains('inventory._begin_idempotency('));
      expect(body, contains("'${entry.value}'"));
      expect(body, contains('inventory._complete_idempotency('));
      expect(
        stocktakeSql,
        contains(
          'grant execute on function inventory.${entry.key}(uuid, text, uuid, jsonb) to authenticated;',
        ),
      );
    }
  });

  test('recount_locks_before_reading_book: pg_advisory_xact_lock precedes reading stock_balances', () {
    final body = fnSection('submit_stocktake_recount');
    final lockPos = body.indexOf('pg_advisory_xact_lock');
    final readBookPos = body.indexOf('from inventory.stock_balances');
    expect(lockPos, greaterThanOrEqualTo(0));
    expect(readBookPos, greaterThan(lockPos));
  });

  test('recount_posts_once: submit_stocktake_recount calls _post_movements exactly once', () {
    final body = fnSection('submit_stocktake_recount');
    final matches = '_post_movements('.allMatches(body).length;
    expect(matches, equals(1));
    expect(body, contains("'STOCKTAKE'"));
    expect(body, contains("'COUNT_GAIN'"));
    expect(body, contains("'COUNT_LOSS'"));
    expect(body, contains("'WRITE_OFF'"));
  });
}
