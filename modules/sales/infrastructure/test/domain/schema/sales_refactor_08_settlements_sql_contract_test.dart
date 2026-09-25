import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Sales refactor bảng 8 `sales.sales_order_settlements`
/// (docs/superpowers/specs/sales-schema-refactor/08-sales-order-settlements.md).
void main() {
  final schemaSql = _readMigration('20260830005_sales_rebuild_schema.sql');
  const removed = ['reconciliation_status', 'last_transaction_at'];

  test('settlement table drops unused columns and keeps settled_at', () {
    final start = schemaSql.indexOf(
      'create table if not exists sales.sales_order_settlements (',
    );
    final table = schemaSql.substring(start, schemaSql.indexOf('\n);', start));
    for (final column in removed) {
      expect(table, isNot(contains(column)), reason: column);
    }
    expect(table, isNot(contains('sales_settlements_recon_status_check')));
    expect(table, contains('settled_at timestamptz,'));
    expect(table, contains("'partially_refunded', 'refunded', 'no_balance'"));
    expect(schemaSql, isNot(contains('alter table sales.sales_order_settlements')));
  });

  test('finalize settlement insert omits removed columns', () {
    final checkoutSql = _readMigration('20260830008_sales_checkout_rpcs.sql');
    final finalize = _lastFunctionBlock(checkoutSql, 'sales.finalize_sales_order');
    final start = finalize.indexOf('insert into sales.sales_order_settlements(');
    final insert = finalize.substring(start, finalize.indexOf('    );', start));
    for (final column in removed) {
      expect(insert, isNot(contains(column)), reason: column);
    }
    expect(insert, isNot(contains("'not_required'")));
    expect(insert, contains('payment_status, settled_at'));
  });

  test('recompute no longer tracks last_transaction_at', () {
    final helperSql = _readMigration('20260830006_sales_shared_rpc_helpers.sql');
    final recompute = _lastFunctionBlock(helperSql, 'sales._recompute_sales_settlement');
    expect(recompute, isNot(contains('last_transaction_at')));
    expect(recompute, isNot(contains('v_last')));
    expect(recompute, isNot(contains('max(confirmed_at)')));
    expect(recompute, contains('then coalesce(settled_at, now())'));
  });
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
