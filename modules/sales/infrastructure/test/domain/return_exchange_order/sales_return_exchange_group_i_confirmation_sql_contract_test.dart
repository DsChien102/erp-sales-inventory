import 'dart:io';

import 'package:test/test.dart';

void main() {
  late final String sql;
  late final String confirmSql;
  late final String completeSql;

  setUpAll(() {
    sql = _readSql(
      draftRelative:
          'supabase/migrations/_drafts/014_sales_return_exchange_confirmation_rpcs.sql',
      promotedRelative:
          'supabase/migrations/20260830014_sales_return_exchange_confirmation_rpcs.sql',
    );
    final normalizeSql = _readSql(
      draftRelative:
          'supabase/migrations/_drafts/016_sales_normalize_outbox_and_commands.sql',
      promotedRelative:
          'supabase/migrations/20260904001_sales_normalize_outbox_and_commands.sql',
    );
    confirmSql = _functionSql(normalizeSql, 'sales.confirm_return_exchange');
    completeSql = _functionSql(sql, 'sales.complete_return_exchange');
  });

  test('declares rebuild confirmation owner and two separate RPCs', () {
    expect(sql, contains('-- Kind: draft'));
    expect(sql, contains('-- Intent: sales_return_exchange_confirmation_rpcs'));
    expect(sql, contains('create or replace function sales.confirm_return_exchange('));
    expect(sql, contains('create or replace function sales.complete_return_exchange('));
    expect(sql, isNot(contains('get_sales_order_return_summary')));
    expect(RegExp('create or replace function').allMatches(sql), hasLength(2));
  });

  test('confirm finalizes to completed single-phase, freezes evidence, and emits lifecycle outbox', () {
    expect(confirmSql, contains("'confirmed'"));
    // Single-phase (TH-05): confirm lands the order at completed directly and
    // never parks it at processing waiting for downstream impact acceptance.
    expect(confirmSql, contains("status = 'completed'"));
    expect(confirmSql, isNot(contains("status = 'processing'")));
    // Return-status projection + completion outbox now happen inside confirm.
    expect(confirmSql, contains('sales_order_return_status_projections'));
    expect(confirmSql, contains("'return_exchange_completed.v1'"));
    expect(confirmSql, contains("'none'"));
    expect(confirmSql, contains("'partially_returned'"));
    expect(confirmSql, contains("'fully_returned'"));
    expect(confirmSql, contains('return_exchange_valuations'));
    expect(confirmSql, contains('settlement_plan'));
    expect(confirmSql, contains('reference_decision'));
    expect(confirmSql, contains("'STALE_VERSION'"));
    expect(confirmSql, contains("'RETURN_QUANTITY_EXCEEDED'"));
    expect(confirmSql, contains("'IDEMPOTENCY_CONFLICT'"));
    expect(confirmSql, contains("set_config('sales.return_exchange_confirmation_context'"));
    expect(confirmSql, contains('sales.settle_return_exchange_difference'));
    expect(confirmSql, isNot(contains('sales._enqueue_inventory_impact_request(')));
    expect(confirmSql, isNot(contains('sales._enqueue_receivable_impact_request(')));
    expect(confirmSql, isNot(contains('insert into sales.inventory_impact_requests')));
    expect(confirmSql, isNot(contains('insert into sales.receivable_impact_requests')));
    expect(confirmSql, isNot(contains('insert into sales.e_invoice_impact_requests')));
    expect(confirmSql, isNot(contains('insert into sales.integration_commands')));
    expect(confirmSql, contains('insert into sales.outbox_messages'));
    expect(confirmSql, contains("'return_exchange_confirmed.v1'"));
    expect(confirmSql, isNot(contains("'sales.pricing.reverse_commitment.v1'")));
    expect(confirmSql, isNot(contains('pricing_reversal_requested')));
    expect(confirmSql, contains('confirmation_decision_snapshot'));
    expect(confirmSql, contains('payment_settled_now_minor'));
    expect(confirmSql, contains('v_collect_debt'));
    expect(confirmSql, contains('Walk-in customers cannot defer payment'));
    expect(confirmSql, contains('Payment due date is required'));
    expect(confirmSql, isNot(contains("lifecycle_status = 'cancelled'")));
    expect(confirmSql, isNot(contains('insert into inventory.')));
  });

  test('confirm auto-settle uses plan correlation and skips zero remainders', () {
    expect(confirmSql, contains("v_plan ->> 'correlation_id'"));
    expect(confirmSql, contains("v_plan ->> 'remainder_collect_minor'"));
    expect(confirmSql, contains("v_plan ->> 'remainder_refund_minor'"));
    expect(confirmSql, contains("Default method='cash'"));
    expect(confirmSql, contains("'collection'"));
    expect(confirmSql, contains("'refund'"));
  });

  test('complete gates on Sales lifecycle only and projects return status', () {
    expect(completeSql, isNot(contains("'IMPACT_PENDING'")));
    expect(completeSql, contains("'completed'"));
    expect(completeSql, contains('sales_order_return_status_projections'));
    expect(completeSql, contains("'none'"));
    expect(completeSql, contains("'partially_returned'"));
    expect(completeSql, contains("'fully_returned'"));
    expect(completeSql, contains("'return_exchange_completed.v1'"));
    expect(completeSql, contains('insert into sales.outbox_messages'));
    expect(completeSql, contains('confirmation_decision_snapshot'));
    expect(completeSql, isNot(contains("lifecycle_status = 'cancelled'")));
    expect(completeSql, isNot(contains('update sales.sales_orders')));
    expect(completeSql, isNot(contains('sales._enqueue_')));
    expect(completeSql, isNot(contains('insert into sales.integration_commands')));
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
