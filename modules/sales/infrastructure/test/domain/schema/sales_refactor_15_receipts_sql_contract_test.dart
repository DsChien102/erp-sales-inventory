import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Sales refactor bảng 15 `sales.sales_receipts`
/// (docs/superpowers/specs/sales-schema-refactor/15-sales-receipts.md).
void main() {
  final schemaSql = _readMigration('20260830005_sales_rebuild_schema.sql');
  final receiptSql = _readMigration('20260830010_sales_inquiry_receipt_rpcs.sql');
  const removed = [
    'template_code',
    'template_version',
    'superseded_by_receipt_id',
    'archived_by_user_id',
    'archived_at',
    'generated_by_user_id',
    'created_at',
  ];

  test('receipts table keeps 8 columns and no supersession pointer', () {
    final start = schemaSql.indexOf('create table if not exists sales.sales_receipts (');
    final table = schemaSql.substring(start, schemaSql.indexOf('\n);', start));
    for (final column in removed) {
      expect(table, isNot(contains(column)), reason: column);
    }
    expect(table, contains('generated_at timestamptz not null default now(),'));
    expect(table, contains('constraint sales_receipts_tenant_id_unique'));
    expect(schemaSql, isNot(contains('alter table sales.sales_receipts')));
    expect(schemaSql, isNot(contains('sales_receipts_tenant_order_id_uidx')));
  });

  test('generate and archive write only kept columns', () {
    final generate = _lastFunctionBlock(receiptSql, 'sales.generate_sales_receipt');
    final insertStart = generate.indexOf('insert into sales.sales_receipts (');
    final insert = generate.substring(insertStart, generate.indexOf('returning * into v_receipt;', insertStart));
    for (final column in removed) {
      expect(insert, isNot(contains(column)), reason: column);
    }
    expect(generate, isNot(contains('superseded_by_receipt_id')));
    expect(generate, contains("set status = 'superseded'\n"));
    final activity = _lastFunctionBlock(receiptSql, 'sales.record_sales_receipt_activity');
    expect(activity, isNot(contains('archived_by_user_id')));
    expect(activity, isNot(contains('archived_at')));
    expect(activity, contains("set status = 'archived'\n"));
  });

  test('audit no longer checks the supersession pointer', () {
    final audit = _lastFunctionBlock(
      _readMigration('20260830006_sales_shared_rpc_helpers.sql'),
      'sales.audit_sales_review_invariants',
    );
    expect(audit, isNot(contains('receipt_superseded_cross_order')));
    expect(audit, isNot(contains('superseded_by_receipt_id')));
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
