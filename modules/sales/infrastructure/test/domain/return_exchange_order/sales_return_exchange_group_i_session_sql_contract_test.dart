import 'dart:io';

import 'package:test/test.dart';

void main() {
  late final String sql;
  late final String startSql;
  late final String updateSql;
  late final String cancelSql;
  late final String contextSql;
  late final String returnableSql;
  late final String precheckSql;

  setUpAll(() {
    sql = _readSql(
      draftRelative:
          'supabase/migrations/_drafts/012_sales_return_exchange_session_rpcs.sql',
      promotedRelative:
          'supabase/migrations/20260830012_sales_return_exchange_session_rpcs.sql',
    );
    startSql = _functionSql(sql, 'sales.start_return_exchange');
    updateSql = _functionSql(sql, 'sales.update_return_exchange');
    cancelSql = _functionSql(sql, 'sales.cancel_return_exchange');
    contextSql = _functionSql(sql, 'sales._get_return_exchange_context');
    returnableSql = _functionSql(sql, 'sales.get_returnable_order_lines');
    precheckSql = _functionSql(sql, 'sales.precheck_return_exchange');
  });

  test('declares rebuild session owner and required RPCs', () {
    expect(sql, contains('-- Kind: draft'));
    expect(sql, contains('-- Intent: sales_return_exchange_session_rpcs'));
    for (final name in <String>[
      'precheck_return_exchange',
      'get_returnable_order_lines',
      '_get_return_exchange_context',
      'start_return_exchange',
      'update_return_exchange',
      'cancel_return_exchange',
    ]) {
      expect(sql, contains('create or replace function sales.$name('));
    }
  });

  test('start/update join returned lines through source sales_order_id', () {
    for (final body in <String>[startSql, updateSql]) {
      expect(body, contains('original_sales_order_line_id'));
      expect(body, contains('source_sales_order_id'));
      expect(body, contains('sales.sales_order_lines'));
      expect(body, contains('sol.sales_order_id = v_order.id'));
      expect(body, contains("'confirmed'"));
      expect(body, contains("'processing'"));
      expect(body, contains("'completed'"));
      expect(body, contains('payload_hash'));
      expect(body, contains("'IDEMPOTENCY_CONFLICT'"));
      expect(body, contains('reference_decision'));
    }
  });

  test('returnable/precheck subtract reserved micros from active operations', () {
    expect(returnableSql, contains('quantity_micros'));
    expect(returnableSql, contains("'returnableQuantity'"));
    expect(returnableSql, contains("'soldQuantity'"));
    expect(returnableSql, contains("'confirmed'"));
    expect(returnableSql, contains("'processing'"));
    expect(returnableSql, contains("'completed'"));
    expect(returnableSql, contains('sales_context_snapshot'));
    expect(precheckSql, contains("'COMPETING_CANCELLATION'"));
    expect(precheckSql, contains('sales.sales_order_cancellations'));
    expect(precheckSql, isNot(contains('for update')));
  });

  test('context keeps line snapshots without undeclared v_currency bug', () {
    expect(contextSql, contains('#variable_conflict use_column'));
    expect(contextSql, isNot(contains('v_currency')));
    expect(contextSql, contains("'lineSnapshot'"));
    expect(contextSql, contains('product_snapshot'));
    expect(contextSql, contains('product_unit_snapshot'));
    expect(contextSql, contains('unit_value_minor'));
    expect(contextSql, contains("'reservationIds'"));
  });

  test('cancel is idempotent without inventory release enqueue', () {
    expect(cancelSql, contains("'IDEMPOTENCY_CONFLICT'"));
    expect(cancelSql, contains("status = 'cancelled'"));
    expect(cancelSql, isNot(contains('sales._enqueue_inventory_impact_request(')));
    expect(cancelSql, isNot(contains('insert into sales.inventory_impact_requests')));
    expect(cancelSql, isNot(contains('insert into sales.integration_commands')));
    expect(cancelSql, contains("'status', 'cancelled'"));
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
