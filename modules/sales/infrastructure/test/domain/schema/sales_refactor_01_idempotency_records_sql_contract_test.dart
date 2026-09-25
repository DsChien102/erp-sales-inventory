import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Sales refactor bảng 1 `sales.idempotency_records`
/// (docs/superpowers/specs/sales-schema-refactor/01-idempotency-records.md).
void main() {
  final schemaSql = _readMigration('20260830005_sales_rebuild_schema.sql');
  final helperSql = _readMigration('20260830006_sales_shared_rpc_helpers.sql');

  test('idempotency_records keeps 7 columns with composite primary key', () {
    final start = schemaSql.indexOf(
      'create table if not exists sales.idempotency_records (',
    );
    final table = schemaSql.substring(start, schemaSql.indexOf('\n);', start));
    expect(
      table,
      contains('primary key (tenant_id, command_scope, idempotency_key)'),
    );
    expect(table, contains('result_snapshot jsonb,'));
    expect(table, contains('created_at timestamptz not null default now(),'));
    expect(
      table,
      contains("check (status in ('in_progress', 'succeeded', 'failed'))"),
    );
    for (final removed in [
      'id uuid primary key',
      'result_type',
      'result_id',
      'correlation_id',
      'expires_at',
      'updated_at',
      "'uncertain'",
    ]) {
      expect(table, isNot(contains(removed)), reason: removed);
    }
  });

  test('begin helper takes 4 parameters and no longer returns record_id', () {
    final body = _lastFunctionBlock(helperSql, 'sales._begin_sales_idempotency');
    expect(
      body,
      contains(
        'sales._begin_sales_idempotency(\n'
        '  p_tenant_id uuid,\n'
        '  p_command_scope text,\n'
        '  p_idempotency_key text,\n'
        '  p_payload_hash text\n'
        ') returns jsonb',
      ),
    );
    expect(body, isNot(contains('p_correlation_id')));
    expect(body, isNot(contains('record_id')));
    expect(body, isNot(contains("'uncertain'")));
    expect(body, contains("'IDEMPOTENCY_CONFLICT'"));
    expect(body, contains('pg_advisory_xact_lock'));
    expect(
      helperSql,
      contains(
        'revoke all on function sales._begin_sales_idempotency(uuid, text, text, text)\n',
      ),
    );
  });

  test('complete helper takes 5 parameters and accepts succeeded/failed only', () {
    final body = _lastFunctionBlock(
      helperSql,
      'sales._complete_sales_idempotency',
    );
    expect(
      body,
      contains(
        'sales._complete_sales_idempotency(\n'
        '  p_tenant_id uuid,\n'
        '  p_command_scope text,\n'
        '  p_idempotency_key text,\n'
        '  p_status text,\n'
        '  p_result_snapshot jsonb\n'
        ') returns void',
      ),
    );
    expect(body, contains("if p_status not in ('succeeded', 'failed') then"));
    for (final removed in ['result_type', 'result_id', 'updated_at', "'uncertain'"]) {
      expect(body, isNot(contains(removed)), reason: removed);
    }
    expect(
      helperSql,
      contains(
        'revoke all on function sales._complete_sales_idempotency(uuid, text, text, text, jsonb)\n',
      ),
    );
  });

  const finalDefinitions = <String, List<String>>{
    '20260830007_sales_draft_rpcs.sql': [
      'sales.save_sales_order_draft',
      'sales.update_sales_order_draft',
      'sales.cancel_sales_order_draft',
    ],
    '20260830008_sales_checkout_rpcs.sql': ['sales.finalize_sales_order'],
    '20260830010_sales_inquiry_receipt_rpcs.sql': [
      'sales.generate_sales_receipt',
      'sales.record_sales_receipt_activity',
    ],
    '20260830012_sales_return_exchange_session_rpcs.sql': [
      'sales.start_return_exchange',
      'sales.update_return_exchange',
      'sales.cancel_return_exchange',
    ],
    '20260830013_sales_return_exchange_settlement_rpcs.sql': [
      'sales.settle_return_exchange_difference',
    ],
    '20260830014_sales_return_exchange_confirmation_rpcs.sql': [
      'sales.complete_return_exchange',
    ],
    '20260904001_sales_normalize_outbox_and_commands.sql': [
      'sales.record_sales_payment',
      'sales.record_sales_refund',
      'sales.confirm_sales_order_cancellation',
      'sales.confirm_return_exchange',
    ],
  };

  test('final definitions call helpers with the new arity', () {
    var beginCalls = 0;
    var completeCalls = 0;
    finalDefinitions.forEach((file, functions) {
      final sql = _readMigration(file);
      for (final fn in functions) {
        final body = _lastFunctionBlock(sql, fn);
        for (final args in _callArgumentCounts(
          body,
          'sales._begin_sales_idempotency(',
        )) {
          expect(args, 4, reason: '$fn begin');
          beginCalls++;
        }
        for (final args in _callArgumentCounts(
          body,
          'sales._complete_sales_idempotency(',
        )) {
          expect(args, 5, reason: '$fn complete');
          completeCalls++;
        }
      }
    });
    expect(beginCalls, 15);
    expect(completeCalls, 18);
  });

  test('checkout drops pre-write snapshot update and uncertain mapping', () {
    final sql = _readMigration('20260830008_sales_checkout_rpcs.sql');
    final finalize = _lastFunctionBlock(sql, 'sales.finalize_sales_order');
    expect(finalize, isNot(contains('Retain recovery scope')));
    expect(finalize, isNot(contains('update sales.idempotency_records')));
    final result = _lastFunctionBlock(sql, 'sales.get_checkout_result');
    expect(result, isNot(contains("'uncertain'")));
    expect(
      result,
      contains("when v_record.status = 'in_progress' then 'processing'"),
    );
  });
}

String _readMigration(String fileName) {
  final root = _findRepoRoot();
  return File('${root.path}/supabase/migrations/$fileName').readAsStringSync();
}

/// Last `create or replace function <qualifiedName>(` … `$$;` in [sql].
String _lastFunctionBlock(String sql, String qualifiedName) {
  final start = sql.lastIndexOf('create or replace function $qualifiedName(');
  if (start < 0) {
    throw StateError('$qualifiedName not found');
  }
  final end = sql.indexOf(r'$$;', start);
  return sql.substring(start, end + 3);
}

Directory _findRepoRoot() {
  var current = Directory.current.absolute;
  while (!Directory('${current.path}/supabase/migrations').existsSync()) {
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not locate Vet45 workspace root');
    }
    current = parent;
  }
  return current;
}

/// Number of top-level arguments of every `<callPrefix>…)` in [sql].
List<int> _callArgumentCounts(String sql, String callPrefix) {
  final counts = <int>[];
  var from = 0;
  while (true) {
    final start = sql.indexOf(callPrefix, from);
    if (start < 0) {
      return counts;
    }
    var depth = 1;
    var commas = 0;
    var inString = false;
    var i = start + callPrefix.length;
    for (; i < sql.length && depth > 0; i++) {
      final ch = sql[i];
      if (ch == "'") {
        inString = !inString;
      } else if (!inString) {
        if (ch == '(') {
          depth++;
        } else if (ch == ')') {
          depth--;
        } else if (ch == ',' && depth == 1) {
          commas++;
        }
      }
    }
    counts.add(commas + 1);
    from = i;
  }
}
