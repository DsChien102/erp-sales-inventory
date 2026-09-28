import 'dart:io';

import 'package:test/test.dart';

/// Xác nhận đổi/trả làm thay đổi nội dung đơn → tăng sales_orders.version
/// (giống hủy đơn) để hóa đơn điện tử/màn hình biết dữ liệu đã cũ.
void main() {
  final sql = _readMigration('20260904001_sales_normalize_outbox_and_commands.sql');

  test('confirm_return_exchange bumps the order version after projecting return status', () {
    final confirm = _lastFunctionBlock(sql, 'sales.confirm_return_exchange');
    const bump = 'update sales.sales_orders\n'
        '  set version = version + 1,\n'
        '      updated_at = now()\n'
        '  where id = v_order.id\n'
        '    and tenant_id = v_order.tenant_id;';
    expect(confirm, contains(bump));
    final bumpAt = confirm.indexOf(bump);
    expect(bumpAt, greaterThan(confirm.indexOf('insert into sales.sales_order_return_status_projections')));
    expect(bumpAt, lessThan(confirm.indexOf("'return_exchange_completed.v1'")));
    expect(confirm, contains('for update;'));
  });
}

String _readMigration(String fileName) {
  final root = _findRepoRoot();
  return File('${root.path}/supabase/migrations/$fileName').readAsStringSync();
}

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
