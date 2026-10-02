import 'dart:io';

import 'package:test/test.dart';

/// Dòng trả từ đơn gốc lưu `unit_value_minor` = giá khách thực trả/đơn vị
/// (đã trừ chiết khấu), khớp tiền hoàn ở evaluate_return_exchange_valuation.
/// Không chép `unit_price_minor` (giá niêm yết khi dòng có chiết khấu).
void main() {
  final sql = _readMigration('20260830012_sales_return_exchange_session_rpcs.sql');

  for (final fn in const ['sales.start_return_exchange', 'sales.update_return_exchange']) {
    test('$fn stores the net unit value for returned original lines', () {
      final body = _lastFunctionBlock(sql, fn);
      expect(
        body,
        contains('select round(sol.line_total_minor::numeric * 1000000 / sol.quantity_micros)::bigint,'),
      );
      expect(body, isNot(contains('select sol.unit_price_minor, sol.product_snapshot')));
    });
  }
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
