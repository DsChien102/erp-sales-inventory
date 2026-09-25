import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — phiếu bán hàng «Đơn gốc»: tính trực tiếp, không lưu,
/// chỉ dòng đơn gốc + khoản thu lúc checkout.
void main() {
  final inquirySql = _readMigration('20260830010_sales_inquiry_receipt_rpcs.sql');

  test('original receipt is read-only with receipt view permission and store scope', () {
    final fn = _lastFunctionBlock(inquirySql, 'sales.get_sales_order_original_receipt');
    expect(fn, contains('p_query_id uuid'));
    expect(fn, contains('p_sales_order_id uuid'));
    expect(fn, contains("iam.has_permission(p_tenant_id, 'sales.receipt.view')"));
    expect(fn, contains('iam.can_access_store(p_tenant_id, v_order.store_id, p_actor_id)'));
    expect(fn, contains("p_tenant_id, p_actor_id, v_order.store_id, 'sales.receipt.view'"));
    expect(fn, isNot(contains('insert into')));
    expect(fn, isNot(contains('update sales.')));
    expect(fn, isNot(contains('_begin_sales_idempotency')));
  });

  test('original receipt prints order lines, sale totals and checkout collections only', () {
    final fn = _lastFunctionBlock(inquirySql, 'sales.get_sales_order_original_receipt');
    expect(
      fn,
      contains("'lines', sales._sales_order_lines_payload(p_tenant_id, p_sales_order_id, v_order.currency_code),"),
    );
    expect(fn, contains("and transaction.source_context = 'checkout'"));
    expect(fn, contains("and transaction.transaction_type = 'collection'"));
    expect(fn, contains("and transaction.status = 'confirmed'"));
    final orderTotal = fn.substring(fn.indexOf("'orderTotal'"), fn.indexOf("'paidTotal'"));
    expect(orderTotal, contains('v_order.payable_amount_minor'));
    expect(fn, contains('greatest(v_order.payable_amount_minor - v_paid_minor, 0)'));
    expect(fn, isNot(contains("'settlementSnapshot'")));
  });

  test('original receipt is granted to authenticated only', () {
    expect(
      inquirySql,
      contains(
        'revoke all on function sales.get_sales_order_original_receipt(uuid, uuid, uuid, uuid) from public, anon;',
      ),
    );
    expect(
      inquirySql,
      contains(
        'grant execute on function sales.get_sales_order_original_receipt(uuid, uuid, uuid, uuid) to authenticated;',
      ),
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
