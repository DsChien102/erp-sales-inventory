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
      throw StateError('Cannot find repo root from ${Directory.current.path}');
    }
    dir = parent;
  }
}

void main() {
  late String sql;

  setUpAll(() {
    final root = _findRepoRoot();
    sql = File(
      '${root.path}/supabase/migrations/20261119001_inventory_reports.sql',
    ).readAsStringSync();
  });

  String fnSection(String fnName) {
    final marker = 'create or replace function inventory.$fnName(';
    final start = sql.indexOf(marker);
    expect(start, greaterThanOrEqualTo(0), reason: 'Missing $marker');
    final nextFn = sql.indexOf(
      'create or replace function inventory.',
      start + marker.length,
    );
    return nextFn > start ? sql.substring(start, nextFn) : sql.substring(start);
  }

  const rpcs = <String, String>{
    'get_stock_report': '(uuid, date, date, text)',
    'get_stock_card': '(uuid, uuid, date, date, uuid)',
    'get_movement_detail': '(uuid, uuid)',
  };
  const ownerRpcs = <String, String>{
    'get_gross_profit_report': '(uuid, date, date, text)',
    'get_supplier_purchase_report': '(uuid, date, date)',
  };
  const helpers = <String, String>{
    '_report_range_check': '(date, date)',
    '_movement_source': '(uuid, text, uuid)',
  };

  test('task1_functions_exist_security_definer_search_path', () {
    for (final name in [...rpcs.keys, ...helpers.keys]) {
      final body = fnSection(name);
      expect(body, contains('security definer'), reason: name);
      expect(
        body,
        contains(
          'set search_path = inventory, iam, catalog, sales, partner, pg_temp',
        ),
        reason: name,
      );
      expect(body, contains('stable'), reason: name);
    }
  });

  test('task1_grants_and_revokes', () {
    rpcs.forEach((name, args) {
      expect(
        sql,
        contains('grant execute on function inventory.$name$args to authenticated;'),
        reason: name,
      );
    });
    helpers.forEach((name, args) {
      expect(
        sql,
        contains(
          'revoke all on function inventory.$name$args from public, anon, authenticated;',
        ),
        reason: name,
      );
      expect(
        sql,
        isNot(contains('grant execute on function inventory.$name$args')),
        reason: name,
      );
    });
  });

  test('task1_assert_actor_first_non_owner_only', () {
    for (final name in rpcs.keys) {
      final body = fnSection(name);
      final assertAt = body.indexOf(
        "inventory._assert_actor(p_tenant_id, 'inventory.read', false)",
      );
      expect(assertAt, greaterThanOrEqualTo(0), reason: name);
      final firstQuery = body.indexOf(RegExp(r'\bfrom (inventory|catalog|sales)\.'));
      expect(firstQuery, greaterThan(assertAt), reason: name);
    }
  });

  test('task1_read_only', () {
    final code = sql
        .split('\n')
        .where((l) => !l.trimLeft().startsWith('--'))
        .join('\n');
    expect(code, isNot(matches(RegExp(r'\binsert\s+into\b'))));
    expect(code, isNot(matches(RegExp(r'\bupdate\s+[a-z_.]+\s+set\b'))));
    expect(code, isNot(matches(RegExp(r'\bdelete\s+from\b'))));
  });

  test('task1_movement_source_kinds', () {
    final body = fnSection('_movement_source');
    for (final kind in [
      'RECEIPT',
      'ORDER',
      'CANCELLATION',
      'RETURN_EXCHANGE',
      'STOCKTAKE',
      'OTHER',
    ]) {
      expect(body, contains("'$kind'"), reason: kind);
    }
  });

  test('task1_stock_card_filters_by_lot_and_masks_value', () {
    final body = fnSection('get_stock_card');
    expect(body, contains('p_lot_id is null or sm.lot_id = p_lot_id'));
    expect(body, contains('v_is_owner and p_lot_id is null'));
  });

  test('task2_owner_only_rpcs_assert_actor_first', () {
    ownerRpcs.forEach((name, args) {
      final body = fnSection(name);
      final assertAt = body.indexOf(
        "inventory._assert_actor(p_tenant_id, 'inventory.read', true)",
      );
      expect(assertAt, greaterThanOrEqualTo(0), reason: name);
      final firstQuery = body.indexOf(RegExp(r'\bfrom (inventory|catalog|sales|partner)\.'));
      expect(firstQuery, greaterThan(assertAt), reason: name);
      expect(
        sql,
        contains('grant execute on function inventory.$name$args to authenticated;'),
        reason: name,
      );
    });
  });

  test('task2_gross_profit_reads_expected_sources', () {
    final body = fnSection('get_gross_profit_report');
    expect(body, contains('cogs_part_vnd'));
    expect(body, contains("'COGS_TRUE_UP'"));
    expect(body, contains('-sum('));
  });
}
