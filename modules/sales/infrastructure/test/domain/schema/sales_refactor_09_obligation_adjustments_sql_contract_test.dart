import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Sales refactor bảng 9
/// `sales.settlement_obligation_adjustments`
/// (docs/superpowers/specs/sales-schema-refactor/09-settlement-obligation-adjustments.md).
void main() {
  final schemaSql = _readMigration('20260830005_sales_rebuild_schema.sql');

  test('adjustments table lives in the settlement section', () {
    final settlements = schemaSql.indexOf(
      'create table if not exists sales.sales_order_settlements (',
    );
    final adjustments = schemaSql.indexOf(
      'create table if not exists sales.settlement_obligation_adjustments (',
    );
    final payments = schemaSql.indexOf(
      'create table if not exists sales.sales_payment_transactions (',
    );
    final evolution = schemaSql.indexOf('SCHEMA EVOLUTION');
    expect(adjustments, greaterThan(settlements));
    expect(adjustments, lessThan(payments));
    expect(adjustments, lessThan(evolution));
    expect(
      'create table if not exists sales.settlement_obligation_adjustments ('
          .allMatches(schemaSql)
          .length,
      1,
    );
  });

  test('audit checks adjustment ledger sum against settlement', () {
    final helperSql = _readMigration('20260830006_sales_shared_rpc_helpers.sql');
    final audit = _lastFunctionBlock(helperSql, 'sales.audit_sales_review_invariants');
    expect(audit, contains("'settlement_adjustment_sum_mismatch'"));
    expect(audit, contains('from sales.settlement_obligation_adjustments adjustment'));
    expect(
      audit,
      contains(
        'where settlement.post_sale_adjustment_amount_minor\n'
        '    is distinct from coalesce(ledger.total_minor, 0)',
      ),
    );
    expect(
      audit.indexOf("'settlement_adjustment_sum_mismatch'"),
      lessThan(audit.indexOf("'return_projection_status_mismatch'")),
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
