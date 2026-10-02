import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('sales_order_lines stores a pricing snapshot', () {
    final sql = _readMigration('20260830005_sales_rebuild_schema.sql');
    final start = sql.indexOf('create table if not exists sales.sales_order_lines (');
    final table = sql.substring(start, sql.indexOf('\n);', start));
    expect(table, contains("  pricing_snapshot jsonb not null default '{}'::jsonb,"));
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
