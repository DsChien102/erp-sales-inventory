import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Sales refactor bảng 14 `sales.return_exchange_valuations`
/// (docs/superpowers/specs/sales-schema-refactor/14-return-exchange-valuations.md).
void main() {
  final schemaSql = _readMigration('20260830005_sales_rebuild_schema.sql');
  final settlementSql = _readMigration('20260830013_sales_return_exchange_settlement_rpcs.sql');
  const removed = [
    'required_settlement_type',
    'version',
    'calculated_by_user_id',
    'confirmed_at',
    'updated_at',
  ];

  test('valuations table drops write-only columns and superseded', () {
    final start = schemaSql.indexOf(
      'create table if not exists sales.return_exchange_valuations (',
    );
    final table = schemaSql.substring(start, schemaSql.indexOf('\n);', start));
    for (final column in removed) {
      expect(table, isNot(contains(column)), reason: column);
    }
    expect(table, isNot(contains('superseded')));
    expect(table, contains("check (status in ('calculated', 'confirmed'))"));
    expect(table, contains('calculated_at timestamptz not null default now(),'));
  });

  test('evaluate upserts only kept columns', () {
    final evaluate = _lastFunctionBlock(
      settlementSql,
      'sales.evaluate_return_exchange_valuation',
    );
    expect(evaluate, isNot(contains('v_required_settlement_type')));
    final start = evaluate.indexOf('insert into sales.return_exchange_valuations (');
    final upsert = evaluate.substring(start, evaluate.indexOf('returning id into v_valuation_id;', start));
    for (final column in removed) {
      expect(upsert, isNot(contains(column)), reason: column);
    }
  });

  test('settle and confirm updates touch only status/details', () {
    final settle = _lastFunctionBlock(
      settlementSql,
      'sales.settle_return_exchange_difference',
    );
    final settleStart = settle.indexOf('update sales.return_exchange_valuations');
    final settleUpdate = settle.substring(settleStart, settle.indexOf(';', settleStart));
    final confirm = _lastFunctionBlock(
      _readMigration('20260904001_sales_normalize_outbox_and_commands.sql'),
      'sales.confirm_return_exchange',
    );
    final confirmStart = confirm.indexOf('update sales.return_exchange_valuations');
    final confirmUpdate = confirm.substring(confirmStart, confirm.indexOf(';', confirmStart));
    for (final update in [settleUpdate, confirmUpdate]) {
      for (final column in removed) {
        expect(update, isNot(contains(column)), reason: column);
      }
      expect(update, contains('status'));
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
