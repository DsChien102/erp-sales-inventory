import 'dart:io';

import 'package:test/test.dart';

/// S3: hàng trả từ dòng gốc định giá theo thành tiền (đã trừ chiết khấu),
/// không theo đơn giá gốc.
void main() {
  test('valuation prorates the original line total for returned goods', () {
    final sql = _readMigration('20260830013_sales_return_exchange_settlement_rpcs.sql');
    final fn = _lastFunctionBlock(sql, 'sales.evaluate_return_exchange_valuation');
    expect(fn, contains('select line_total_minor, quantity_micros\n        into v_orig_line_total_minor, v_orig_quantity_micros'));
    expect(fn, contains('round(v_orig_line_total_minor::numeric * v_line.quantity_micros / v_orig_quantity_micros)::bigint'));
    expect(fn, isNot(contains('select unit_price_minor into v_unit_price_minor')));
    expect(fn, contains('v_return_value_minor := v_return_value_minor + v_line_value_minor;'));
  });

  test('returnable lines expose the net unit price', () {
    final sql = _readMigration('20260830012_sales_return_exchange_session_rpcs.sql');
    final fn = _lastFunctionBlock(sql, 'sales.get_returnable_order_lines');
    expect(fn, contains("round(l.line_total_minor::numeric * 1000000 / l.quantity_micros)::bigint"));
    expect(fn, isNot(contains("'amountMinor', l.unit_price_minor,")));
  });
}

String _readMigration(String fileName) {
  var dir = Directory.current.absolute;
  while (!Directory('${dir.path}/supabase/migrations').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) throw StateError('Could not locate Vet45 workspace root');
    dir = parent;
  }
  return File('${dir.path}/supabase/migrations/$fileName').readAsStringSync();
}

String _lastFunctionBlock(String sql, String qualifiedName) {
  final start = sql.lastIndexOf('create or replace function $qualifiedName(');
  if (start < 0) throw StateError('$qualifiedName not found');
  final end = sql.indexOf(r'$$;', start);
  return sql.substring(start, end + 3);
}
