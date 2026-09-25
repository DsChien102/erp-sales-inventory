import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Sales refactor bảng 16 `sales.sales_receipt_activities`
/// (docs/superpowers/specs/sales-schema-refactor/16-sales-receipt-activities.md).
void main() {
  final schemaSql = _readMigration('20260830005_sales_rebuild_schema.sql');

  test('receipt activities keep 6 columns with required actor', () {
    final start = schemaSql.indexOf(
      'create table if not exists sales.sales_receipt_activities (',
    );
    final table = schemaSql.substring(start, schemaSql.indexOf('\n);', start));
    for (final column in [
      'channel',
      'destination_masked',
      'device_context',
      'activity_metadata',
      'created_at',
    ]) {
      expect(table, isNot(contains(column)), reason: column);
    }
    expect(table, contains('actor_user_id uuid not null,'));
    expect(table, contains('occurred_at timestamptz not null default now(),'));
    expect(table, contains("check (activity_type in ('printed', 'shared', 'archived'))"));
  });

  test('activity insert still writes exactly the kept columns', () {
    final receiptSql = _readMigration('20260830010_sales_inquiry_receipt_rpcs.sql');
    expect(
      receiptSql,
      contains(
        'insert into sales.sales_receipt_activities (\n'
        '    id, tenant_id, sales_receipt_id, actor_user_id, activity_type, occurred_at\n'
        '  )',
      ),
    );
  });
}

String _readMigration(String fileName) {
  final root = _findRepoRoot();
  return File('${root.path}/supabase/migrations/$fileName').readAsStringSync();
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
