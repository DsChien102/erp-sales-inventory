import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Sales refactor bảng 11 `sales.sales_order_cancellations`
/// (docs/superpowers/specs/sales-schema-refactor/11-sales-order-cancellations.md).
void main() {
  final schemaSql = _readMigration('20260830005_sales_rebuild_schema.sql');
  // `version` is checked separately: it is a substring of kept `source_order_version`.
  const removed = [
    'confirmed_by_user_id',
    'completed_by_user_id',
    'required_impacts_snapshot',
    'blocker_codes',
    'idempotency_key',
    'requested_at',
    'completed_at',
    'blocked_at',
    'failed_at',
    'updated_at',
  ];

  test('cancellations table keeps 10 columns and one cancellation per order', () {
    final start = schemaSql.indexOf(
      'create table if not exists sales.sales_order_cancellations (',
    );
    final table = schemaSql.substring(start, schemaSql.indexOf('\n);', start));
    for (final column in removed) {
      expect(table, isNot(contains(column)), reason: column);
    }
    expect(table, isNot(contains('  version bigint')));
    expect(table, contains('unique (tenant_id, sales_order_id)'));
    expect(table, contains("'completed', 'blocked', 'failed', 'cancelled'"));
    expect(schemaSql, isNot(contains('sales_order_cancellations_one_completed')));
    expect(schemaSql, isNot(contains('alter table sales.sales_order_cancellations')));
  });

  test('confirm inserts kept columns and has no key-based lookup', () {
    final confirm = _lastFunctionBlock(
      _readMigration('20260904001_sales_normalize_outbox_and_commands.sql'),
      'sales.confirm_sales_order_cancellation',
    );
    expect(confirm, isNot(contains('v_existing')));
    final start = confirm.indexOf('insert into sales.sales_order_cancellations (');
    final insert = confirm.substring(start, confirm.indexOf('returning * into v_inserted;', start));
    for (final column in removed) {
      expect(insert, isNot(contains(column)), reason: column);
    }
    expect(insert, isNot(contains('status, version,')));
  });

  test('readers use requested_by_user_id as the cancelling actor', () {
    final get = _lastFunctionBlock(
      _readMigration('20260830011_sales_adjustment_cancellation_rpcs.sql'),
      'sales.get_sales_order_cancellation',
    );
    expect(get, contains('v_cancel_actor_id := v_cancellation.requested_by_user_id;'));
    final timeline = _lastFunctionBlock(
      _readMigration('20260830010_sales_inquiry_receipt_rpcs.sql'),
      'sales.get_sales_order_timeline',
    );
    expect(timeline, contains('select c.requested_by_user_id::text'));
    expect(timeline, isNot(contains('c.completed_by_user_id')));
    expect(timeline, isNot(contains('c.confirmed_by_user_id')));
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
