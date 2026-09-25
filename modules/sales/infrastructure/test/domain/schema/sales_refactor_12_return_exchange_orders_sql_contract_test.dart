import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Sales refactor bảng 12 `sales.return_exchange_orders`
/// (docs/superpowers/specs/sales-schema-refactor/12-return-exchange-orders.md).
void main() {
  final schemaSql = _readMigration('20260830005_sales_rebuild_schema.sql');
  final rxSql = _readMigration('20260830012_sales_return_exchange_session_rpcs.sql');
  const removed = [
    'reason_code',
    'idempotency_key',
    'payload_hash',
    'operation_type',
    'causation_id',
    'cancelled_at',
  ];

  test('return_exchange_orders drops dead columns and keeps reason', () {
    final start = schemaSql.indexOf(
      'create table if not exists sales.return_exchange_orders (',
    );
    final table = schemaSql.substring(start, schemaSql.indexOf('\n);', start));
    for (final column in removed) {
      expect(table, isNot(contains(column)), reason: column);
    }
    expect(table, contains('  reason text,'));
    expect(table, contains('correlation_id text,'));
    expect(table, contains('entry_source text,'));
  });

  test('start and update accept optional reason and persist it', () {
    for (final fn in ['sales.start_return_exchange', 'sales.update_return_exchange']) {
      final body = _lastFunctionBlock(rxSql, fn);
      expect(
        body,
        contains("  reference_decision jsonb default '{}'::jsonb,\n  reason text default null\n) returns jsonb"),
        reason: fn,
      );
    }
    final start = _lastFunctionBlock(rxSql, 'sales.start_return_exchange');
    expect(start, contains("nullif(btrim(start_return_exchange.reason), '')"));
    final update = _lastFunctionBlock(rxSql, 'sales.update_return_exchange');
    expect(update, contains("reason = nullif(btrim(update_return_exchange.reason), ''),"));
    expect(
      rxSql,
      contains(
        'grant execute on function sales.start_return_exchange(text, uuid, uuid, uuid, text, jsonb, text, text, text, text, integer, jsonb, text) to authenticated;',
      ),
    );
    expect(
      rxSql,
      contains(
        'grant execute on function sales.update_return_exchange(text, uuid, uuid, uuid, jsonb, text, text, text, text, integer, jsonb, text) to authenticated;',
      ),
    );
  });

  test('start/update/cancel no longer write or read dropped columns', () {
    final start = _lastFunctionBlock(rxSql, 'sales.start_return_exchange');
    final update = _lastFunctionBlock(rxSql, 'sales.update_return_exchange');
    final cancel = _lastFunctionBlock(rxSql, 'sales.cancel_return_exchange');
    expect(start, isNot(contains('v_existing')));
    expect(start, isNot(contains("'SESSION'")));
    expect(start, isNot(contains('operation_type')));
    expect(update, isNot(contains('operation_type')));
    expect(update, isNot(contains('v_session.payload_hash')));
    expect(update, isNot(contains('v_session.idempotency_key')));
    expect(update, isNot(contains('causation_id = ')));
    expect(cancel, isNot(contains('cancelled_at')));
    final insertStart = start.indexOf('insert into sales.return_exchange_orders (');
    final insert = start.substring(insertStart, start.indexOf(') values', insertStart));
    for (final column in removed) {
      expect(insert, isNot(contains(column)), reason: column);
    }
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
