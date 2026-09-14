import 'dart:io';

import 'package:test/test.dart';

void main() {
  late final String sql;

  setUpAll(() {
    sql = _draftSqlFile().readAsStringSync();
  });

  test('declares rebuild receipt RPCs on the inquiry/receipt owner', () {
    expect(sql, contains('-- Kind: draft'));
    expect(sql, contains('-- Intent: sales_inquiry_receipt_rpcs'));
    expect(sql, contains('create or replace function sales.generate_sales_receipt('));
    expect(sql, contains('create or replace function sales.get_sales_receipt('));
    expect(sql, contains('create or replace function sales.record_sales_receipt_activity('));
    expect(sql, contains('create or replace function sales._sales_receipt_envelope('));
  });

  test('generate is server-authoritative with insert-before-supersede', () {
    final function = _functionSql(sql, 'sales.generate_sales_receipt');
    expect(function, contains('p_command_id uuid'));
    expect(function, contains('p_idempotency_key text'));
    expect(function, contains('p_payload_hash text'));
    expect(function, isNot(contains('p_receipt_snapshot')));
    expect(function, contains('sales.sales_order_settlements'));
    expect(function, contains('sales.sales_payment_transactions'));
    expect(function, contains('sales.sales_order_lines'));
    expect(function, contains('receipt_snapshot'));
    expect(function, contains("'receiptNumber'"));
    expect(function, contains("'orderNumber'"));
    expect(function, contains('sales._begin_sales_idempotency('));
    final insertAt = function.indexOf('insert into sales.sales_receipts');
    final supersedeAt = function.indexOf('superseded_by_receipt_id');
    expect(insertAt, greaterThan(-1));
    expect(supersedeAt, greaterThan(insertAt));
    expect(function, contains("'superseded'"));
  });

  test('get returns stored envelope with store scope via order', () {
    final function = _functionSql(sql, 'sales.get_sales_receipt');
    expect(function, contains('p_query_id uuid'));
    expect(function, contains('p_receipt_id uuid'));
    expect(function, contains("iam.has_permission(p_tenant_id, 'sales.receipt.view')"));
    expect(function, contains('scope.store_id = v_order.store_id'));
    expect(function, contains('return sales._sales_receipt_envelope(v_receipt)'));
  });

  test('activity authorizes by type, appends, and never mutates order/settlement', () {
    final function = _functionSql(sql, 'sales.record_sales_receipt_activity');
    expect(function, contains("p_activity_type not in ('printed', 'shared', 'archived')"));
    expect(function, contains("when 'printed' then 'sales.receipt.print'"));
    expect(function, contains("when 'shared' then 'sales.receipt.share'"));
    expect(function, contains("when 'archived' then 'sales.receipt.archive'"));
    expect(function, contains('insert into sales.sales_receipt_activities'));
    expect(function, contains('scope.store_id = v_order.store_id'));
    expect(function, isNot(contains('update sales.sales_orders')));
    expect(function, isNot(contains('update sales.sales_order_settlements')));
  });

  test('helper stays private and envelope keeps document payload', () {
    final helper = _functionSql(sql, 'sales._sales_receipt_envelope');
    expect(helper, contains("'document'"));
    expect(
      sql,
      contains(
        'revoke all on function sales._sales_receipt_envelope(sales.sales_receipts) from public, anon;',
      ),
    );
    expect(
      sql,
      isNot(
        contains('grant execute on function sales._sales_receipt_envelope(sales.sales_receipts)'),
      ),
    );
    expect(sql, isNot(contains('from catalog.')));
    expect(sql, isNot(contains('from partner.')));
    expect(sql, isNot(contains('from pricing.')));
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
