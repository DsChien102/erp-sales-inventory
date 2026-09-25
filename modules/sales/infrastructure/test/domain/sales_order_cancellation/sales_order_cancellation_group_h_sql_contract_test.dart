import 'dart:io';

import 'package:test/test.dart';

void main() {
  late final String sql;
  late final String precheckSql;
  late final String confirmSql;
  late final String detailSql;
  late final String listSql;

  setUpAll(() {
    sql = _readSql(
      draftRelative: 'supabase/migrations/_drafts/011_sales_adjustment_cancellation_rpcs.sql',
      promotedRelative: 'supabase/migrations/20260830011_sales_adjustment_cancellation_rpcs.sql',
    );
    final normalizeSql = _readSql(
      draftRelative: 'supabase/migrations/_drafts/016_sales_normalize_outbox_and_commands.sql',
      promotedRelative: 'supabase/migrations/20260904001_sales_normalize_outbox_and_commands.sql',
    );
    precheckSql = _functionSql(sql, 'sales.precheck_sales_order_cancellation');
    confirmSql = _functionSql(
      normalizeSql,
      'sales.confirm_sales_order_cancellation',
    );
    detailSql = _functionSql(sql, 'sales.get_sales_order_cancellation');
    listSql = _functionSql(sql, 'sales.list_sales_order_cancellation_reasons');
  });

  test('declares rebuild cancellation + reason catalog RPCs', () {
    expect(sql, contains('-- Kind: draft'));
    expect(sql, contains('-- Intent: sales_cancellation_rpcs'));
    expect(sql, contains('create or replace function sales.precheck_sales_order_cancellation('));
    expect(sql, contains('create or replace function sales.confirm_sales_order_cancellation('));
    expect(sql, contains('create or replace function sales.get_sales_order_cancellation('));
    expect(
      sql,
      contains('create or replace function sales.list_sales_order_cancellation_reasons('),
    );
    expect(sql, isNot(contains('create table')));
    expect(sql, isNot(contains(_removedPolicyTable)));
  });

  test('cancellation schema stores optional text without reason code', () {
    final schema = _readSql(
      draftRelative: 'supabase/migrations/_drafts/005_sales_rebuild_schema.sql',
      promotedRelative: 'supabase/migrations/20260830005_sales_rebuild_schema.sql',
    );
    final start = schema.indexOf('create table if not exists sales.sales_order_cancellations (');
    final end = schema.indexOf('\n);', start);
    final cancellationTable = schema.substring(start, end);
    expect(cancellationTable, contains('reason text,'));
    expect(cancellationTable, isNot(contains('reason_code')));
    expect(confirmSql, contains("nullif(v_reason_text, '')"));
    expect(confirmSql, isNot(contains('reason_code')));
    expect(schema, isNot(contains('alter table sales.sales_order_cancellations')));
  });

  test('precheck is read-only with settlement net and blockers', () {
    expect(precheckSql, contains("iam.has_permission(tenant_id, 'sales.order.cancel')"));
    expect(precheckSql, contains('net_collected_amount_minor'));
    expect(precheckSql, contains("'PAYMENT_ALREADY_COLLECTED'"));
    expect(precheckSql, contains("'ORDER_ALREADY_CANCELLED'"));
    expect(precheckSql, contains("'COMPETING_CANCELLATION'"));
    expect(precheckSql, contains("'RETURN_EXCHANGE_CONFLICT'"));
    expect(precheckSql, contains("'DRAFT_RETURN_ACTIVE'"));
    expect(precheckSql, contains("'allowed'"));
    expect(precheckSql, contains("'sourceSettlementVersion'"));
    expect(precheckSql, isNot(contains('insert into')));
    expect(RegExp(r'\bupdate\s+sales\.', caseSensitive: false).hasMatch(precheckSql), isFalse);
  });

  test('confirm compares order/settlement versions before mutation', () {
    expect(confirmSql, contains('expected_order_version'));
    expect(confirmSql, contains('expected_settlement_version'));
    expect(confirmSql, contains("'STALE_VERSION'"));
    final versionAt = confirmSql.indexOf('expected_order_version');
    final updateAt = confirmSql.indexOf("set lifecycle_status = 'cancelled'");
    expect(versionAt, greaterThan(-1));
    expect(updateAt, greaterThan(versionAt));
    expect(confirmSql, isNot(contains(_removedPolicyTable)));
    expect(confirmSql, contains('sales._begin_sales_idempotency('));
  });

  test('confirm emits lifecycle outbox facts without Model B handoff enqueue', () {
    expect(confirmSql, isNot(contains('sales._enqueue_inventory_impact_request(')));
    expect(confirmSql, isNot(contains('sales._enqueue_receivable_impact_request(')));
    expect(confirmSql, isNot(contains('insert into sales.e_invoice_impact_requests')));
    expect(confirmSql, isNot(contains('insert into sales.integration_commands')));
    expect(confirmSql, contains("set lifecycle_status = 'cancelled'"));
    expect(confirmSql, contains("'sales_order_cancellation_confirmed.v1'"));
    expect(confirmSql, contains("'sales_order_cancelled.v1'"));
    expect(confirmSql, contains("'sales_reporting_cancellation_recorded.v1'"));
    expect(confirmSql, contains('insert into sales.outbox_messages'));
    expect(confirmSql, contains("'inventory', 'not_required'"));
    expect(confirmSql, contains("'receivable', 'not_required'"));
    expect(confirmSql, contains("'eInvoice', 'not_required'"));
    expect(confirmSql, isNot(contains("'sales.pricing.reverse_commitment.v1'")));
    expect(confirmSql, isNot(contains('pricing_reversal_requested')));
    expect(confirmSql, isNot(contains("'sales.order.cancelled'")));
    expect(confirmSql, isNot(contains('insert into sales.sales_payment_transactions')));
    expect(confirmSql, isNot(contains('refund_treatment')));
  });

  test('detail and reason list keep frozen envelopes', () {
    expect(detailSql, contains("'result'"));
    expect(detailSql, contains("'reason'"));
    expect(detailSql, contains("'cancelledAt'"));
    expect(detailSql, contains("'cancelledByActorId'"));
    expect(detailSql, contains("'cancelledByActorName'"));
    expect(detailSql, contains('iam.platform_user_profiles'));
    expect(detailSql, contains('auth.users'));
    expect(detailSql, isNot(contains("'Nhân viên'")));
    expect(detailSql, contains("'netConfirmedCollectionMinor'"));
    expect(listSql, contains("iam.has_permission(tenant_id, 'sales.order.cancel')"));
    expect(listSql, isNot(contains(_removedPolicyTable)));
    expect(listSql, contains("'displayName'"));
    expect(listSql, contains("'requiresNote'"));
    expect(listSql, contains("'sortOrder'"));
  });

  test('reason catalog uses default cancel reasons without policy storage', () {
    expect(listSql, contains("'CUSTOMER_REQUEST'"));
    expect(listSql, contains("'Khách yêu cầu hủy'"));
    expect(listSql, contains("'DUPLICATE'"));
    expect(listSql, contains("'Tạo trùng đơn'"));
    expect(listSql, contains("'OTHER'"));
    expect(listSql, contains("'Lý do khác'"));
    expect(confirmSql, isNot(contains('REASON_POLICY_UNAVAILABLE')));
    expect(confirmSql, isNot(contains('v_policy_found')));
    expect(confirmSql, isNot(contains('reason_code')));
    expect(detailSql, isNot(contains('reasonCode')));
    expect(detailSql, contains("'reasonText', coalesce(v_cancellation.reason, '')"));
  });
}

const _removedPolicyTable =
    'cancellation_reason_'
    'policy';

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
