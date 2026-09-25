import 'dart:io';

import 'package:test/test.dart';

void main() {
  late final String sql;
  late final String normalizedSql;
  late final String finalizeSql;

  setUpAll(() {
    sql = _readSql(
      draftRelative: 'supabase/migrations/_drafts/008_sales_checkout_rpcs.sql',
      promotedRelative:
          'supabase/migrations/20260830008_sales_checkout_rpcs.sql',
    );
    normalizedSql = _squash(sql);
    finalizeSql = _functionSql(sql, 'sales.finalize_sales_order');
  });

  test('declares rebuild finalize/status owners with frozen mapper params', () {
    expect(sql, contains('-- Kind: draft'));
    expect(sql, contains('-- Intent: sales_checkout_rpcs'));
    expect(sql, contains('create or replace function sales.finalize_sales_order('));
    expect(sql, contains('create or replace function sales.get_checkout_result('));
    expect(sql, contains('p_command_id uuid'));
    expect(sql, contains('p_source_draft_id uuid'));
    expect(sql, contains('p_commercial_snapshot jsonb'));
    expect(sql, contains('p_payment_due_date date default null'));
    expect(sql, contains('p_idempotency_key text'));
    expect(sql, contains('p_payload_hash text'));
    expect(sql, contains('p_correlation_id text'));
    expect(sql, contains('p_causation_id text'));
    expect(sql, contains('p_expected_source_version'));
    expect(sql, isNot(contains('p_order_totals')));
    expect(sql, isNot(contains('p_sales_context_snapshot')));
  });

  test('enforces settlement-before-payment and lifecycle outbox fact writes', () {
    final settlementInsert = finalizeSql.indexOf(
      'insert into sales.sales_order_settlements',
    );
    final paymentInsert = finalizeSql.indexOf(
      'insert into sales.sales_payment_transactions',
    );
    expect(settlementInsert, greaterThan(-1));
    expect(paymentInsert, greaterThan(settlementInsert));

    final orderInsert = finalizeSql.indexOf('insert into sales.sales_orders');
    final lineInsert = finalizeSql.indexOf('insert into sales.sales_order_lines');
    expect(finalizeSql, isNot(contains('checkout_attempt')));
    expect(orderInsert, greaterThan(-1));
    expect(lineInsert, greaterThan(orderInsert));
    expect(settlementInsert, greaterThan(lineInsert));

    expect(finalizeSql, isNot(contains('sales._enqueue_inventory_impact_request(')));
    expect(finalizeSql, isNot(contains('sales._enqueue_receivable_impact_request(')));
    expect(finalizeSql, isNot(contains('insert into sales.inventory_impact_requests')));
    expect(finalizeSql, isNot(contains('insert into sales.receivable_impact_requests')));
    expect(finalizeSql, isNot(contains('insert into sales.e_invoice_impact_requests')));
    expect(finalizeSql, isNot(contains('insert into sales.integration_commands')));
    expect(finalizeSql, contains("'sales_order_finalized.v1'"));
    expect(finalizeSql, isNot(contains('from inventory.')));
    expect(finalizeSql, isNot(contains('from accounting.')));
    expect(finalizeSql, contains('insert into sales.outbox_messages'));
    expect(finalizeSql, isNot(contains('insert into sales.outbox ')));
  });

  test('keeps recoverable idempotency lifecycle and stable checkout envelopes', () {
    expect(finalizeSql, contains("'succeeded'"));
    expect(finalizeSql, contains("'blocked'"));
    expect(finalizeSql, contains("'failed'"));
    expect(finalizeSql, contains('IDEMPOTENCY_CONFLICT'));
    expect(finalizeSql, contains('STALE_VERSION'));
    expect(finalizeSql, contains('CHECKOUT_BLOCKED'));
    expect(finalizeSql, contains("'idempotencyKey'"));
    expect(finalizeSql, isNot(contains('checkoutAttemptId')));
    expect(finalizeSql, contains("return v_decision->'result_snapshot'->'checkoutResult'"));
    expect(finalizeSql, contains("'checkoutResult', v_result"));
    expect(finalizeSql, contains("'requestedByUserId', p_actor_id"));
    expect(finalizeSql, contains('v_request_hash := md5(v_request::text)'));
    expect(finalizeSql, contains("'salesOrderId'"));
    expect(finalizeSql, contains("'salesOrderVersion'"));
    expect(finalizeSql, contains("p_commercial_snapshot -> 'lines'"));
    expect(finalizeSql, contains("'lineId', v_order_line_id::text"));
    expect(finalizeSql, contains("set status = 'converted'"));
    // Dedup đi qua IdempotencyRecord (helper tự advisory-lock), đúng mô hình tài liệu.
    expect(finalizeSql, contains('_begin_sales_idempotency'));
    expect(finalizeSql, contains('_complete_sales_idempotency'));
    expect(finalizeSql, contains("'finalize_sales_order'"));
    expect(
      finalizeSql,
      isNot(contains('gen_random_uuid();\n  exception when others')),
    );
  });

  test('finalize revalidates catalog sellable state before durable writes', () {
    expect(finalizeSql, contains('PRODUCT_NOT_SELLABLE'));
    expect(finalizeSql, contains('catalog.products'));
    expect(finalizeSql, contains('catalog.product_units'));
    expect(
      finalizeSql,
      contains("p.business_status = 'active'::catalog.product_business_status"),
    );
    expect(finalizeSql, contains('p.is_ready_to_sell = true'));
    expect(finalizeSql, contains('pu.is_active = true'));
    expect(finalizeSql, contains("Sản phẩm đã ngừng bán. Vui lòng quay lại đơn."));
  });

  test('finalize keeps receivable due-date gate without impact enqueue', () {
    expect(finalizeSql, contains('payment_due_date'));
    expect(finalizeSql, contains('p_payment_due_date'));
    expect(finalizeSql, contains('RECEIVABLE_DUE_DATE_REQUIRED'));
    expect(finalizeSql, isNot(contains('p_due_date => p_payment_due_date')));
    expect(finalizeSql, isNot(contains("'dueAt', p_payment_due_date")));
  });

  test('result lookup enforces scope before returning durable results', () {
    final statusSql = _functionSql(sql, 'sales.get_checkout_result');
    expect(statusSql, contains('CHECKOUT_RESULT_NOT_FOUND'));
    expect(statusSql, contains("p_tenant_id, p_actor_id, p_store_id, 'sales.order.view'"));
    expect(statusSql, contains("command_scope = 'finalize_sales_order'"));
    expect(statusSql, contains("is distinct from p_store_id::text"));
    expect(statusSql, contains('or p_actor_id is null or p_store_id is null'));
    expect(statusSql, contains("when v_record.status = 'in_progress' then 'processing'"));
    expect(statusSql, isNot(contains("'uncertain'")));
    expect(statusSql, contains('result_snapshot'));
    expect(normalizedSql, contains('grant execute on function sales.finalize_sales_order'));
    expect(
      normalizedSql,
      contains('grant execute on function sales.get_checkout_result'),
    );
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

String _squash(String value) => value.replaceAll(RegExp(r'\s+'), ' ').trim();
