import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — phiếu bán hàng in sản phẩm hiện tại sau đổi/trả:
/// đơn gốc − hàng đã trả + hàng đổi mới; Tổng đơn = phải trả hiện tại.
void main() {
  final inquirySql = _readMigration('20260830010_sales_inquiry_receipt_rpcs.sql');

  test('receipt lines payload reads the shared current-lines helper', () {
    final payload = _lastFunctionBlock(inquirySql, 'sales._sales_receipt_lines_payload');
    expect(payload, contains('from sales._sales_order_current_lines(p_tenant_id, p_sales_order_id) unit'));
    final helper = _lastFunctionBlock(inquirySql, 'sales._sales_order_current_lines');
    expect(helper, contains("rl.line_role = 'returned'"));
    expect(helper, contains("xl.line_role = 'exchange'"));
    expect(helper, contains("in ('confirmed', 'processing', 'completed')"));
    expect(helper, contains('where unit.remaining_micros > 0'));
    expect(
      inquirySql,
      contains(
        'revoke all on function sales._sales_receipt_lines_payload(uuid, uuid, text) from public, anon, authenticated;',
      ),
    );
    expect(
      inquirySql.indexOf('create or replace function sales._sales_receipt_lines_payload('),
      lessThan(inquirySql.indexOf('create or replace function sales.generate_sales_receipt(')),
    );
  });

  test('generate prints current lines and current payable as order total', () {
    final receipt = _lastFunctionBlock(inquirySql, 'sales.generate_sales_receipt');
    expect(
      receipt,
      contains('v_receipt_lines := sales._sales_receipt_lines_payload(p_tenant_id, p_sales_order_id, v_order.currency_code);'),
    );
    expect(receipt, contains("'lines', v_receipt_lines,"));
    expect(receipt, isNot(contains('sales._sales_order_lines_payload(')));
    final orderTotal = receipt.substring(receipt.indexOf("'orderTotal'"), receipt.indexOf("'paidTotal'"));
    expect(orderTotal, contains('v_settlement.current_payable_amount_minor'));
  });

  test('generate nets payments per method from confirmed transactions', () {
    final receipt = _lastFunctionBlock(inquirySql, 'sales.generate_sales_receipt');
    expect(receipt, contains("transaction.status = 'confirmed'"));
    expect(receipt, contains("when transaction.transaction_type = 'refund' then -transaction.amount_minor"));
    expect(receipt, contains('group by transaction.payment_method_code'));
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
