import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Sales refactor bảng 13 `sales.return_exchange_lines`
/// (docs/superpowers/specs/sales-schema-refactor/13-return-exchange-lines.md).
void main() {
  final schemaSql = _readMigration('20260830005_sales_rebuild_schema.sql');
  const removed = ['line_value_minor', 'pricing_snapshot', 'line_note', 'updated_at'];

  test('return_exchange_lines drops dead columns and owns all checks', () {
    final start = schemaSql.indexOf(
      'create table if not exists sales.return_exchange_lines (',
    );
    final table = schemaSql.substring(start, schemaSql.indexOf('\n);', start));
    for (final column in removed) {
      expect(table, isNot(contains(column)), reason: column);
    }
    expect(table, contains('constraint return_exchange_lines_base_qty_positive'));
    expect(table, contains('constraint return_exchange_lines_unit_value_nonneg'));
    expect(table, contains('constraint return_exchange_lines_returned_single_source'));
    expect(schemaSql, isNot(contains('returned_source_xor')));
    expect(schemaSql, isNot(contains('alter table sales.return_exchange_lines')));
  });

  final rxSql = _readMigration('20260830012_sales_return_exchange_session_rpcs.sql');

  test('conversion helpers mirror checkout rules', () {
    final rate = _lastFunctionBlock(rxSql, 'sales._product_unit_conversion_rate');
    expect(rate, contains('from catalog.products p'));
    expect(rate, contains('pu.conversion_rate_to_base'));
    expect(rate, contains("'PRODUCT_NOT_SELLABLE'"));
    final base = _lastFunctionBlock(rxSql, 'sales._base_quantity_micros');
    expect(base, contains("'INVALID_QUANTITY'"));
    expect(base, contains('v_base <> trunc(v_base)'));
    expect(
      rxSql.indexOf('create or replace function sales._base_quantity_micros('),
      lessThan(rxSql.indexOf('create or replace function sales.start_return_exchange(')),
    );
  });

  for (final fn in ['sales.start_return_exchange', 'sales.update_return_exchange']) {
    test('$fn stores converted base quantity and no dropped columns', () {
      final body = _lastFunctionBlock(rxSql, fn);
      expect(body, contains('v_base_qty := sales._base_quantity_micros('));
      expect(body, contains("'conversionRateToBase',\n        sales._product_unit_conversion_rate("));
      expect(body, contains('v_qty, v_base_qty, v_unit_price_minor,'));
      expect(body, isNot(contains('v_qty, v_qty')));
      final start = body.indexOf('insert into sales.return_exchange_lines (');
      final insert = body.substring(start, body.indexOf('end loop;', start));
      for (final column in removed) {
        expect(insert, isNot(contains(column)), reason: column);
      }
      expect(insert, isNot(contains("'unitPriceMinor'")));
      expect(body, contains('sol.product_id, sol.product_unit_id'));
      expect(body, contains('rl.product_id, rl.product_unit_id'));
      expect(body, contains('Hàng trả phải cùng sản phẩm và đơn vị với dòng gốc.'));
    });
  }

  test('valuation no longer reads pricing_snapshot', () {
    final evaluate = _lastFunctionBlock(
      _readMigration('20260830013_sales_return_exchange_settlement_rpcs.sql'),
      'sales.evaluate_return_exchange_valuation',
    );
    expect(evaluate, isNot(contains('pricing_snapshot')));
    expect(evaluate, contains('v_unit_price_minor := v_line.unit_value_minor;'));
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
