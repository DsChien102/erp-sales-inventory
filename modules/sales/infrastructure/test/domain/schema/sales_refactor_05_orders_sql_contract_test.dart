import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Sales refactor bảng 5 `sales.sales_orders`
/// (docs/superpowers/specs/sales-schema-refactor/05-sales-orders.md).
void main() {
  final schemaSql = _readMigration('20260830005_sales_rebuild_schema.sql');
  const removed = [
    'sales_shift_id',
    'reference_code',
    'customer_snapshot',
    'pricing_summary_snapshot',
    'business_time',
    'locked_at',
    'locked_by_user_id',
  ];

  test('sales_orders drops unused columns and owns commercial balance check', () {
    final start = schemaSql.indexOf('create table if not exists sales.sales_orders (');
    final table = schemaSql.substring(start, schemaSql.indexOf('\n);', start));
    for (final column in removed) {
      expect(table, isNot(contains(column)), reason: column);
    }
    for (final kept in [
      'channel_code varchar(50) not null,',
      "lock_status text not null default 'unlocked',",
      'sales_context_snapshot jsonb not null,',
      'buyer_tax_snapshot jsonb,',
      'cancelled_at timestamptz,',
      'payment_due_date date,',
      'constraint sales_orders_commercial_balance',
    ]) {
      expect(table, contains(kept), reason: kept);
    }
  });

  test('schema evolution block no longer alters sales_orders', () {
    expect(schemaSql, isNot(contains('alter table sales.sales_orders')));
  });

  test('finalize insert omits removed columns', () {
    final checkoutSql = _readMigration('20260830008_sales_checkout_rpcs.sql');
    final finalize = _lastFunctionBlock(checkoutSql, 'sales.finalize_sales_order');
    final insertStart = finalize.indexOf('insert into sales.sales_orders(');
    final insert = finalize.substring(
      insertStart,
      finalize.indexOf(');', finalize.indexOf(') values (', insertStart)),
    );
    for (final column in removed) {
      expect(insert, isNot(contains(column)), reason: column);
    }
    expect(insert, contains("p_actor_id, p_customer_id, 'pos', v_currency_code,"));
  });

  test('receipt reads customer from sales_context_snapshot', () {
    final inquirySql = _readMigration('20260830010_sales_inquiry_receipt_rpcs.sql');
    final receipt = _lastFunctionBlock(inquirySql, 'sales.generate_sales_receipt');
    expect(receipt, contains("'customer', v_order.sales_context_snapshot -> 'customer',"));
    expect(receipt, isNot(contains('customer_snapshot')));
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
