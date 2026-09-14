import 'dart:io';

import 'package:test/test.dart';

void main() {
  late final String sql;
  late final String policySql;
  late final String detailSql;

  setUpAll(() {
    sql = _readSql(
      draftRelative:
          'supabase/migrations/_drafts/012_sales_return_exchange_session_rpcs.sql',
      promotedRelative:
          'supabase/migrations/20260830012_sales_return_exchange_session_rpcs.sql',
    );
    policySql = _functionSql(sql, 'sales.get_return_exchange_form_policy');
    detailSql = _functionSql(sql, 'sales.get_return_exchange_detail');
  });

  test('declares form policy and detail on rebuild session owner', () {
    expect(sql, contains('-- Kind: draft'));
    expect(sql, contains('-- Intent: sales_return_exchange_session_rpcs'));
    expect(sql, contains('create or replace function sales.get_return_exchange_form_policy('));
    expect(sql, contains('create or replace function sales.get_return_exchange_detail('));
    expect(sql, isNot(contains('create table')));
    expect(sql, isNot(contains('sales.return_exchange_reason_policy')));
    expect(sql, isNot(contains('sales.return_exchange_condition_policy')));
  });

  test('form policy preserves permission and returns empty catalogs', () {
    expect(policySql, contains('auth.uid() is distinct from actor_id'));
    expect(
      policySql,
      contains("iam.has_permission(tenant_id, 'sales.return_exchange.create')"),
    );
    expect(policySql, contains("'reasons', '[]'::jsonb"));
    expect(policySql, contains("'conditions', '[]'::jsonb"));
    expect(policySql, isNot(contains("'displayName'")));
    expect(policySql, isNot(contains("'sortOrder'")));
    expect(policySql, isNot(contains('is_active is true')));
  });

  test('detail returns nested FE envelope without mutating owners', () {
    expect(detailSql, contains("iam.has_permission(tenant_id, 'sales.return_exchange.view')"));
    expect(detailSql, contains("'DATA_SCOPE_DENIED'"));
    expect(detailSql, contains("'referenceNumber'"));
    expect(detailSql, contains("'entrySource'"));
    expect(detailSql, contains("'completionReady'"));
    expect(detailSql, contains("'settlementPlan'"));
    expect(detailSql, contains("'valuation'"));
    expect(detailSql, contains("'impacts'"));
    expect(detailSql, contains("v_impacts := '[]'::jsonb"));
    expect(detailSql, isNot(contains('inventory_impact_requests')));
    expect(detailSql, isNot(contains('receivable_impact_requests')));
    expect(detailSql, isNot(contains('e_invoice_impact_requests')));
    expect(detailSql, isNot(contains('insert into catalog.')));
    expect(detailSql, isNot(contains('insert into inventory.')));
    expect(detailSql, isNot(contains("lifecycle_status = 'cancelled'")));
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
