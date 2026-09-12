import 'dart:io';

import 'package:test/test.dart';

void main() {
  late final String sql;
  late final String evaluateSql;
  late final String settleSql;

  setUpAll(() {
    sql = _readSql(
      draftRelative:
          'supabase/migrations/_drafts/013_sales_return_exchange_settlement_rpcs.sql',
      promotedRelative:
          'supabase/migrations/20260830013_sales_return_exchange_settlement_rpcs.sql',
    );
    evaluateSql = _functionSql(sql, 'sales.evaluate_return_exchange_valuation');
    settleSql = _functionSql(sql, 'sales.settle_return_exchange_difference');
  });

  test('declares rebuild settlement owner and two RPCs', () {
    expect(sql, contains('-- Kind: draft'));
    expect(sql, contains('-- Intent: sales_return_exchange_settlement_rpcs'));
    expect(sql, contains('create or replace function sales.evaluate_return_exchange_valuation('));
    expect(sql, contains('create or replace function sales.settle_return_exchange_difference('));
    expect(sql, isNot(contains('confirm_return_exchange')));
    expect(sql, isNot(contains('complete_return_exchange')));
  });

  test('evaluate uses Theme 5 / ADR-2 sign and authoritative line/pricing sources', () {
    expect(evaluateSql, contains('exchange_value_minor - return_value_minor'));
    expect(evaluateSql, isNot(contains('return_value_minor - exchange_value_minor')));
    expect(evaluateSql, contains('from sales.sales_order_lines'));
    expect(evaluateSql, contains('unit_price_minor'));
    expect(evaluateSql, contains('exchange_pricing_by_product_unit_id'));
    expect(evaluateSql, contains('pricing_source_version'));
    expect(evaluateSql, contains('source_order_version'));
    expect(evaluateSql, contains('source_settlement_version'));
    expect(evaluateSql, contains("'STALE_VERSION'"));
    expect(evaluateSql, contains('insert into sales.return_exchange_valuations'));
    expect(evaluateSql, contains("'settlementPlan'"));
    expect(evaluateSql, contains("'settlementDifference'"));
    expect(evaluateSql, contains('v_is_walk_in'));
    expect(evaluateSql, contains('customer_partner_id is null'));
    expect(evaluateSql, isNot(contains('insert into sales.sales_payment_transactions')));
    expect(evaluateSql, isNot(contains('insert into sales.receivable_impact_requests')));
  });

  test('evaluate plan splits positive/negative difference without payment writes', () {
    expect(evaluateSql, contains('collect_amount_minor'));
    expect(evaluateSql, contains('refund_amount_minor'));
    expect(evaluateSql, contains('receivable_create_amount_minor'));
    expect(evaluateSql, contains('receivable_reverse_amount_minor'));
    expect(evaluateSql, contains('net_collected_amount_minor'));
    expect(evaluateSql, contains('valuation_details'));
  });

  test('settle locks, appends payments/refunds, and keeps receivable plan in Sales', () {
    expect(settleSql, contains('for update'));
    expect(settleSql, contains('pg_advisory_xact_lock'));
    expect(settleSql, contains("'collection'"));
    expect(settleSql, contains("'refund'"));
    expect(settleSql, contains("'IDEMPOTENCY_CONFLICT'"));
    expect(settleSql, contains("'STALE_VERSION'"));
    expect(settleSql, contains('expected_source_version'));
    expect(settleSql, contains('insert into sales.sales_payment_transactions'));
    expect(settleSql, isNot(contains('sales._enqueue_receivable_impact_request(')));
    expect(settleSql, isNot(contains('v_handoff')));
    expect(settleSql, isNot(contains('impactRequestId')));
    expect(settleSql, contains('pending_receivable_create_minor'));
    expect(settleSql, contains('pending_receivable_reverse_minor'));
    expect(settleSql, isNot(contains('insert into sales.receivable_impact_requests')));
    expect(settleSql, isNot(contains('insert into sales.integration_commands')));
    expect(settleSql, contains('processed_collect_minor'));
    expect(settleSql, contains('processed_refund_minor'));
    expect(settleSql, contains('remainder_collect_minor'));
    expect(settleSql, contains('remainder_refund_minor'));
    expect(settleSql, contains('sales._recompute_sales_settlement('));
    expect(settleSql, contains("current_setting('sales.return_exchange_confirmation_context'"));
    expect(settleSql, contains('sales.payment.record'));
    expect(settleSql, contains('sales.payment.refund'));
    expect(settleSql, contains('amount_minor is null or amount_minor <= 0'));
    expect(settleSql, isNot(contains('insert into accounting.')));
    expect(settleSql, isNot(contains('insert into receivable.')));
  });
}

String _readSql({
  required String draftRelative,
  required String promotedRelative,
}) {
  final candidates = <File>[
    File(draftRelative),
    File('../../../$draftRelative'),
    File('../../../../$draftRelative'),
    File(promotedRelative),
    File('../../../$promotedRelative'),
    File('../../../../$promotedRelative'),
  ];
  for (final candidate in candidates) {
    if (candidate.existsSync()) {
      return candidate.readAsStringSync();
    }
  }
  throw StateError('Missing SQL for $draftRelative / $promotedRelative');
}

String _functionSql(String sql, String function) {
  final start = sql.indexOf('create or replace function $function(');
  if (start < 0) throw StateError('Missing function $function.');
  final end = sql.indexOf('\n\$\$;', start);
  if (end < 0) throw StateError('Missing terminator for $function.');
  return sql.substring(start, end + '\n\$\$;'.length);
}
