import 'dart:io';

import 'package:test/test.dart';

/// SQL contract — dòng hiện tại của đơn sau đổi/trả, dùng chung cho phiếu in
/// và nguồn hóa đơn điện tử (spec 2026-09-25 §4.1).
void main() {
  final inquirySql = _readMigration('20260830010_sales_inquiry_receipt_rpcs.sql');

  test('current lines helper nets returns, adds exchange lines, exposes gross', () {
    final helper = _lastFunctionBlock(inquirySql, 'sales._sales_order_current_lines');
    expect(helper, contains('returns table ('));
    expect(helper, contains('line_kind text'));
    expect(helper, contains('gross_minor bigint'));
    expect(helper, contains('from sales.sales_order_lines l'));
    expect(helper, contains("'original'::text as line_kind"));
    expect(helper, contains("'exchange'::text"));
    expect(helper, contains("rl.line_role = 'returned'"));
    expect(helper, contains('rl.original_sales_order_line_id = l.id'));
    expect(helper, contains("xl.line_role = 'exchange'"));
    expect(helper, contains('rl.source_exchange_line_id = xl.id'));
    expect(helper, contains("in ('confirmed', 'processing', 'completed')"));
    expect(helper, contains('where unit.remaining_micros > 0'));
    expect(helper, contains('unit.line_total_minor + unit.discount_minor'));
    expect(
      inquirySql,
      contains(
        'revoke all on function sales._sales_order_current_lines(uuid, uuid) from public, anon, authenticated;',
      ),
    );
  });

  test('receipt payload reads the helper and keeps its json shape', () {
    final payload = _lastFunctionBlock(inquirySql, 'sales._sales_receipt_lines_payload');
    expect(payload, contains('from sales._sales_order_current_lines(p_tenant_id, p_sales_order_id) unit'));
    expect(payload, isNot(contains('from sales.sales_order_lines')));
    for (final key in ["'lineId'", "'product'", "'unit'", "'quantityMicros'", "'unitPrice'", "'discountTotal'", "'lineTotal'", "'note'"]) {
      expect(payload, contains(key));
    }
    expect(payload, contains('order by unit.sort_group, unit.sort_at, unit.sort_seq, unit.line_id'));
    expect(
      inquirySql.indexOf('create or replace function sales._sales_order_current_lines('),
      lessThan(inquirySql.indexOf('create or replace function sales._sales_receipt_lines_payload(')),
    );
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
