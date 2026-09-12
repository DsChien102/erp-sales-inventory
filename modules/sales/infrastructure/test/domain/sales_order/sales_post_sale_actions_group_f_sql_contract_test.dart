import 'dart:io';

import 'package:test/test.dart';

void main() {
  late final String sql;

  setUpAll(() {
    sql = _readSql(
      draftRelative: 'supabase/migrations/_drafts/011_sales_adjustment_cancellation_rpcs.sql',
      promotedRelative:
          'supabase/migrations/20260830011_sales_adjustment_cancellation_rpcs.sql',
    );
  });

  test('declares rebuild post-sale availability owner on 011', () {
    expect(sql, contains('-- Kind: draft'));
    expect(sql, contains('-- Intent: sales_cancellation_rpcs'));
    expect(sql, contains('create or replace function sales.get_available_post_sale_actions('));
    expect(sql, isNot(contains('create or replace function sales.precheck_return_exchange(')));
  });

  test('availability is advisory-only with permission, scope, and camelCase keys', () {
    final body = _functionSql(sql, 'sales.get_available_post_sale_actions');
    expect(body, contains("iam.has_permission(tenant_id, 'sales.order.view')"));
    expect(body, contains('iam.membership_store_scopes'));
    expect(body, contains('expected_source_version'));
    expect(body, contains("'STALE_VERSION'"));
    expect(body, contains("'canCancel'"));
    expect(body, contains("'canReturnExchange'"));
    expect(body, isNot(contains("'canAdjust'")));
    expect(body, isNot(contains('precheck_order_adjustment(')));
    expect(body, isNot(contains('precheck_sales_order_cancellation(')));
    expect(body, isNot(contains('insert into')));
    expect(body, isNot(contains('update sales.')));
  });
}

String _readSql({
  required String draftRelative,
  required String promotedRelative,
}) {
  final candidates = [
    File(draftRelative),
    File('../../../$draftRelative'),
    File('../../../../$draftRelative'),
    File(promotedRelative),
    File('../../../$promotedRelative'),
    File('../../../../$promotedRelative'),
  ];
  for (final candidate in candidates) {
    if (candidate.existsSync()) return candidate.readAsStringSync();
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
