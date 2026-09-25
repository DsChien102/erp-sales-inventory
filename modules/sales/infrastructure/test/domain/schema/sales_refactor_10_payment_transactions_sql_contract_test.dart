import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Sales refactor bảng 10 `sales.sales_payment_transactions`
/// (docs/superpowers/specs/sales-schema-refactor/10-sales-payment-transactions.md).
void main() {
  final schemaSql = _readMigration('20260830005_sales_rebuild_schema.sql');
  const removed = [
    'transaction_code',
    'idempotency_key',
    'confirmed_by_user_id',
    'confirmed_at',
    'voided_at',
    'metadata',
    'updated_at',
  ];

  test('payment transactions table drops dead columns and void values', () {
    final start = schemaSql.indexOf(
      'create table if not exists sales.sales_payment_transactions (',
    );
    final table = schemaSql.substring(start, schemaSql.indexOf('\n);', start));
    for (final column in removed) {
      expect(table, isNot(contains(column)), reason: column);
    }
    expect(table, isNot(contains("'reversal'")));
    expect(table, isNot(contains("'voided'")));
    expect(table, contains("check (status in ('pending', 'confirmed', 'failed'))"));
    expect(table, contains('constraint sales_payment_tx_type_direction'));
    expect(table, contains('constraint sales_payment_tx_tenant_settlement_id_unique'));
    expect(table, contains('constraint sales_payment_tx_related_same_settlement_fk'));
    expect(table, isNot(contains('sales_payment_tx_related_fk\n')));
    expect(table, contains('payment_method_snapshot jsonb,'));
    expect(table, contains('external_reference varchar(150),'));
  });

  test('schema evolution block no longer touches payment transactions', () {
    expect(schemaSql, isNot(contains('alter table sales.sales_payment_transactions')));
    expect(schemaSql, isNot(contains('sales_payment_tx_tenant_settlement_id_uidx')));
  });

  const inserts = <String, String>{
    'sales.finalize_sales_order': '20260830008_sales_checkout_rpcs.sql',
    'sales.record_sales_payment': '20260904001_sales_normalize_outbox_and_commands.sql',
    'sales.record_sales_refund': '20260904001_sales_normalize_outbox_and_commands.sql',
    'sales.settle_return_exchange_difference':
        '20260830013_sales_return_exchange_settlement_rpcs.sql',
  };
  inserts.forEach((fn, file) {
    test('$fn inserts only kept payment columns', () {
      final body = _lastFunctionBlock(_readMigration(file), fn);
      final start = body.indexOf('insert into sales.sales_payment_transactions');
      final insert = body.substring(start, body.indexOf(') values', start));
      for (final column in removed) {
        expect(insert, isNot(contains(column)), reason: column);
      }
      expect(insert, contains('initiated_by_user_id'));
    });
  });

  test('refund no longer checks legacy reversals', () {
    final refund = _lastFunctionBlock(
      _readMigration('20260904001_sales_normalize_outbox_and_commands.sql'),
      'sales.record_sales_refund',
    );
    expect(refund, isNot(contains("'reversal'")));
    expect(refund, contains("and refund.status = 'confirmed';"));
  });

  test('void_sales_payment no longer exists in any migration', () {
    final dir = Directory('${_findRepoRoot().path}/supabase/migrations');
    for (final file in dir.listSync().whereType<File>()) {
      if (!file.path.endsWith('.sql')) continue;
      expect(
        file.readAsStringSync(),
        isNot(contains('sales.void_sales_payment')),
        reason: file.path,
      );
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
