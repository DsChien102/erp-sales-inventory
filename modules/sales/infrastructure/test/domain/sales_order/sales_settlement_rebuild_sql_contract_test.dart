import 'dart:io';

import 'package:test/test.dart';

void main() {
  late final String sql;
  late final String normalizeSql;
  late final String paymentSql;
  late final String refundSql;

  setUpAll(() {
    sql = _readSql(
      draftRelative: 'supabase/migrations/_drafts/009_sales_settlement_rpcs.sql',
      promotedRelative:
          'supabase/migrations/20260830009_sales_settlement_rpcs.sql',
    );
    normalizeSql = _readSql(
      draftRelative:
          'supabase/migrations/_drafts/016_sales_normalize_outbox_and_commands.sql',
      promotedRelative:
          'supabase/migrations/20260904001_sales_normalize_outbox_and_commands.sql',
    );
    paymentSql = _functionSql(normalizeSql, 'sales.record_sales_payment');
    refundSql = _functionSql(normalizeSql, 'sales.record_sales_refund');
  });

  test('declares rebuild settlement owner and public RPCs', () {
    expect(sql, contains('-- Kind: draft'));
    expect(sql, contains('-- Intent: sales_settlement_rpcs'));
    expect(normalizeSql, contains('create or replace function sales.record_sales_payment('));
    expect(normalizeSql, contains('create or replace function sales.record_sales_refund('));
    expect(sql, contains('sales._assert_sales_actor('));
    expect(sql, contains('sales._begin_sales_idempotency('));
    expect(sql, contains('sales._complete_sales_idempotency('));
    expect(sql, contains('sales._recompute_sales_settlement('));
  });

  test('payment and refund use payload-hash idempotency with conflict handling', () {
    for (final body in <String>[paymentSql, refundSql]) {
      expect(body, contains("'IDEMPOTENCY_CONFLICT'"));
      expect(body, contains('payload_hash'));
      expect(body, contains('sales._begin_sales_idempotency('));
      expect(body, contains('sales._complete_sales_idempotency('));
      expect(body, contains("'replay'"));
    }
  });

  test('payment rejects overpayment against outstanding', () {
    expect(paymentSql, contains('outstanding_amount_minor'));
    expect(paymentSql, contains('OVERPAYMENT_NOT_ALLOWED'));
    expect(paymentSql, contains('p_amount_minor >'));
  });

  test('refund validates refundable capacity and same-settlement related tx', () {
    expect(refundSql, contains('REFUND_EXCEEDS_COLLECTED'));
    expect(refundSql, contains('net_collected_amount_minor'));
    expect(refundSql, contains('related_transaction_id'));
    expect(refundSql, contains('sales_order_settlement_id = v_settlement_id'));
  });

  test('mutations recompute settlement and emit canonical fact + settlement_changed', () {
    for (final body in <String>[paymentSql, refundSql]) {
      expect(body, contains('sales._recompute_sales_settlement('));
      expect(body, contains("'sales_settlement_changed.v1'"));
    }
    expect(paymentSql, contains("'sales_payment_recorded.v1'"));
    expect(refundSql, contains("'sales_refund_recorded.v1'"));
    expect(paymentSql, isNot(contains("'sales.payment.recorded'")));
    expect(refundSql, isNot(contains("'sales.payment.refunded'")));
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
