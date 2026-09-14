import 'dart:io';

import 'package:test/test.dart';

void main() {
  late final String sql;

  setUpAll(() {
    sql = _draftSqlFile().readAsStringSync();
  });

  test('declares rebuild inquiry owner and seven S15-S18 read RPCs', () {
    expect(sql, contains('-- Kind: draft'));
    expect(sql, contains('-- Intent: sales_inquiry_receipt_rpcs'));
    for (final name in <String>[
      'list_sales_orders',
      'search_sales_orders',
      'get_sales_order_detail',
      'get_sales_order_settlement',
      'get_sales_order_payment_transactions',
      'get_sales_order_timeline',
      'get_sales_order_return_summary',
    ]) {
      expect(sql, contains('create or replace function sales.$name('));
    }
  });

  test('list/search preserve cursor pages, camelCase keys, and store scope', () {
    expect(sql, contains("'hasMore'"));
    expect(sql, contains("'nextCursor'"));
    expect(sql, contains("'salesOrderId'"));
    expect(sql, contains("'lifecycleStatus'"));
    expect(sql, contains("'settlementStatus'"));
    expect(sql, contains("'totalMatching'"));
    expect(sql, contains("'facets'"));
    expect(sql, contains('has_outstanding_receivable boolean default null'));
    expect(sql, contains('iam.membership_store_scopes'));
    expect(sql, contains('auth.uid() is distinct from actor_id'));
    expect(sql, contains("iam.has_permission(tenant_id, 'sales.order.view')"));
    expect(sql, contains('list_sales_orders.store_id is null'));
    expect(sql, contains('o.store_id = list_sales_orders.store_id'));
    expect(sql, contains('order by created_at desc, id desc'));
    expect(sql, contains('limit least(greatest(page_size, 1), 100) + 1'));
    expect(sql, contains('sales_context_snapshot'));
    expect(sql, contains('order_code'));
    expect(sql, contains("'orderNumber'"));
    expect(sql, contains("customer ->> 'displayName'"));
    expect(sql, contains("customer ->> 'phoneNumber'"));
    expect(sql, isNot(contains('from catalog.')));
    expect(sql, isNot(contains('from partner.')));
    expect(sql, isNot(contains('create table inventory.')));
    expect(sql, isNot(contains('create table receivable.')));
  });

  test('list reads canonical settlement and committed timestamp columns', () {
    final listSql = _functionSql(sql, 'sales.list_sales_orders');
    expect(listSql, contains('o.occurred_at as created_at'));
    expect(listSql, contains('select payment_status'));
    expect(
      listSql,
      isNot(contains('select status\n        from sales.sales_order_settlements')),
    );
  });

  test('settlement/payment reads use rebuild money columns and wire camelCase status', () {
    final settlementSql = _functionSql(sql, 'sales.get_sales_order_settlement');
    final txSql = _functionSql(sql, 'sales.get_sales_order_payment_transactions');
    expect(settlementSql, contains('current_payable_amount_minor'));
    expect(settlementSql, contains('collected_amount_minor'));
    expect(settlementSql, contains('outstanding_amount_minor'));
    expect(settlementSql, contains('payment_status'));
    expect(settlementSql, contains("'partiallyPaid'"));
    expect(txSql, contains('sales_order_settlement_id'));
    expect(txSql, contains('payment_method_code'));
    expect(txSql, contains("'hasMore'"));
  });

  test('detail/timeline/return summary stay on committed sales projections', () {
    final detailSql = _functionSql(sql, 'sales.get_sales_order_detail');
    final timelineSql = _functionSql(sql, 'sales.get_sales_order_timeline');
    final returnSql = _functionSql(sql, 'sales.get_sales_order_return_summary');
    expect(detailSql, contains('sales.sales_orders'));
    expect(detailSql, contains('sales.sales_receipts'));
    expect(detailSql, contains("'currentReceiptId'"));
    expect(timelineSql, contains("'occurredAt'"));
    expect(returnSql, contains('sales.return_exchange_orders'));
    expect(returnSql, contains('sales.return_exchange_valuations'));
  });
}

File _draftSqlFile() {
  const relativePath = 'supabase/migrations/_drafts/010_sales_inquiry_receipt_rpcs.sql';
  final candidates = [
    File(relativePath),
    File('../../../$relativePath'),
    File('../../../../$relativePath'),
  ];
  for (final candidate in candidates) {
    if (candidate.existsSync()) return candidate;
  }
  return candidates.first;
}

String _functionSql(String sql, String function) {
  final start = sql.indexOf('create or replace function $function(');
  if (start < 0) throw StateError('Missing function $function.');
  final end = sql.indexOf('\n\$\$;', start);
  if (end < 0) throw StateError('Missing terminator for $function.');
  return sql.substring(start, end + '\n\$\$;'.length);
}
