import 'dart:io';

import 'package:test/test.dart';

void main() {
  late final String helperSql;
  late final String lowerHelperSql;

  setUpAll(() {
    helperSql = _readSql(
      draftRelative: 'supabase/migrations/_drafts/006_sales_shared_rpc_helpers.sql',
      promotedRelative:
          'supabase/migrations/20260830006_sales_shared_rpc_helpers.sql',
    );
    lowerHelperSql = helperSql.toLowerCase();
  });

  test('declares shared helper owner header', () {
    expect(helperSql, contains('-- Kind: draft'));
    expect(helperSql, contains('-- Intent: sales_shared_rpc_helpers'));
    expect(
      helperSql,
      contains(
        '-- Touches: _assert_sales_actor, _begin_sales_idempotency, '
        '_complete_sales_idempotency, _recompute_sales_settlement',
      ),
    );
    expect(helperSql, isNot(contains('_enqueue_inventory_impact_request')));
    expect(helperSql, isNot(contains('_enqueue_receivable_impact_request')));
  });

  test('defines required shared helpers with security definer and search_path', () {
    for (final name in <String>[
      '_assert_sales_actor',
      '_begin_sales_idempotency',
      '_complete_sales_idempotency',
      '_recompute_sales_settlement',
    ]) {
      expect(helperSql, contains('create or replace function sales.$name('));
      final fn = _functionSql(helperSql, 'sales.$name');
      expect(fn.toLowerCase(), contains('security definer'));
      expect(
        fn.toLowerCase(),
        contains('set search_path = sales, iam, public, pg_temp'),
      );
    }
  });

  test('revokes public execution of shared helpers', () {
    expect(
      lowerHelperSql,
      contains('revoke all on function sales._assert_sales_actor'),
    );
    expect(
      lowerHelperSql,
      contains('revoke all on function sales._begin_sales_idempotency'),
    );
    expect(
      lowerHelperSql,
      contains('revoke all on function sales._complete_sales_idempotency'),
    );
    expect(
      lowerHelperSql,
      contains('revoke all on function sales._recompute_sales_settlement'),
    );
    expect(
      lowerHelperSql,
      isNot(contains('revoke all on function sales._enqueue_inventory_impact_request')),
    );
    expect(
      lowerHelperSql,
      isNot(contains('revoke all on function sales._enqueue_receivable_impact_request')),
    );
    expect(lowerHelperSql, contains('from public, anon, authenticated'));
  });

  test('idempotency begin locks, conflicts on payload, and returns decision envelope', () {
    expect(helperSql, contains('create or replace function sales._begin_sales_idempotency('));
    expect(helperSql, contains("'IDEMPOTENCY_CONFLICT'"));
    expect(helperSql, contains('payload_hash is distinct from'));
    expect(helperSql, contains('result_snapshot'));
    expect(helperSql, contains("'new'"));
    expect(helperSql, contains("'replay'"));
    expect(helperSql, contains("'in_progress'"));
    expect(helperSql, contains('pg_advisory_xact_lock'));
    expect(helperSql, contains('for update'));
  });

  test('settlement recompute uses confirmed inflow/outflow and clears settled_at', () {
    expect(helperSql, contains("direction = 'inflow' and status = 'confirmed'"));
    expect(helperSql, contains("direction = 'outflow' and status = 'confirmed'"));
    expect(helperSql, contains('greatest(current_payable_amount_minor -'));
    expect(helperSql, contains('settled_at = case'));
    expect(helperSql, contains('else null'));
  });

  test('assert actor checks auth permission and nullable store scope', () {
    final fn = _functionSql(helperSql, 'sales._assert_sales_actor');
    expect(fn, contains('auth.uid()'));
    expect(fn, contains('iam.has_permission'));
    expect(fn, contains('iam.can_access_store('));
    expect(fn, contains('p_store_id is null'));
    expect(fn, contains("'PERMISSION_DENIED'"));
    expect(fn, contains("'DATA_SCOPE_DENIED'"));
  });

  test('omits Model B handoff enqueue helpers and impact/command inserts', () {
    expect(helperSql, isNot(contains('create or replace function sales._enqueue_')));
    expect(helperSql, isNot(contains('insert into sales.inventory_impact_requests')));
    expect(helperSql, isNot(contains('insert into sales.receivable_impact_requests')));
    expect(helperSql, isNot(contains('insert into sales.integration_commands')));
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
  if (start < 0) {
    throw StateError('Missing function $function.');
  }
  final end = sql.indexOf('\n\$\$;', start);
  if (end < 0) {
    throw StateError('Missing terminator for $function.');
  }
  return sql.substring(start, end + '\n\$\$;'.length);
}
