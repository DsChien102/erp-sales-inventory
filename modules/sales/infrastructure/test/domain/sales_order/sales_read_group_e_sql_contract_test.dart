import 'dart:io';

import 'package:test/test.dart';

void main() {
  late final String sql;

  setUpAll(() {
    sql = _draftSqlFile().readAsStringSync();
  });

  test('declares rebuild inquiry/receipt owner and required public RPCs', () {
    expect(sql, contains('-- Kind: draft'));
    expect(sql, contains('-- Intent: sales_inquiry_receipt_rpcs'));
    for (final name in <String>[
      'get_sales_order',
      'get_sales_order_payment_summary',
      'get_order_integration_status',
      'list_sales_orders',
      'search_sales_orders',
      'get_sales_order_detail',
      'get_sales_order_settlement',
      'get_sales_order_payment_transactions',
      'get_sales_order_timeline',
      'get_sales_order_return_summary',
      'generate_sales_receipt',
      'get_sales_receipt',
      'record_sales_receipt_activity',
    ]) {
      expect(sql, contains('create or replace function sales.$name('));
    }
  });

  test('read RPCs preserve camelCase envelopes and store scope', () {
    expect(sql, contains("'hasMore'"));
    expect(sql, contains("'nextCursor'"));
    expect(sql, contains("'salesOrderId'"));
    expect(sql, contains("'lifecycleStatus'"));
    expect(sql, contains("'committedAt'"));
    expect(sql, contains('iam.membership_store_scopes'));
    expect(sql, contains('sales_context_snapshot'));
    expect(sql, contains('order_code'));
    expect(sql, isNot(contains('from catalog.')));
    expect(sql, isNot(contains('from partner.')));
    expect(sql, isNot(contains('from pricing.')));
  });

  test('receipt generate is server-authoritative with insert-before-supersede', () {
    final generateSql = _functionSql(sql, 'sales.generate_sales_receipt');
    expect(generateSql, isNot(contains('p_receipt_snapshot')));
    expect(generateSql, contains('sales.sales_order_settlements'));
    expect(generateSql, contains('sales.sales_payment_transactions'));
    expect(generateSql, contains('sales.sales_order_lines'));
    expect(generateSql, contains('receipt_snapshot'));
    final insertAt = generateSql.indexOf('insert into sales.sales_receipts');
    final supersedeAt = generateSql.indexOf('superseded_by_receipt_id');
    expect(insertAt, greaterThan(-1));
    expect(supersedeAt, greaterThan(insertAt));
    expect(generateSql, contains("'superseded'"));
    expect(generateSql, contains('sales._begin_sales_idempotency('));
  });

  test('receipt activity resolves store scope through receipt to order', () {
    final activitySql = _functionSql(sql, 'sales.record_sales_receipt_activity');
    expect(activitySql, contains("when 'printed' then 'sales.receipt.print'"));
    expect(activitySql, contains("when 'shared' then 'sales.receipt.share'"));
    expect(activitySql, contains("when 'archived' then 'sales.receipt.archive'"));
    expect(activitySql, contains('insert into sales.sales_receipt_activities'));
    expect(activitySql, contains('from sales.sales_orders'));
    expect(activitySql, contains('scope.store_id = v_order.store_id'));
    expect(activitySql, isNot(contains('update sales.sales_orders')));
    expect(activitySql, isNot(contains('update sales.sales_order_settlements')));
  });
}

File _draftSqlFile() {
  const relativePath =
      'supabase/migrations/_drafts/010_sales_inquiry_receipt_rpcs.sql';
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
