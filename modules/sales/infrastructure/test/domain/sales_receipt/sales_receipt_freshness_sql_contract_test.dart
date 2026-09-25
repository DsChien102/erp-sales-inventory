import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — phiếu bán hàng được tạo lại sau khi quyết toán đổi
/// (đổi/trả, thu thêm, hoàn tiền) thay vì đọc lại bản chụp cũ.
void main() {
  final inquirySql = _readMigration('20260830010_sales_inquiry_receipt_rpcs.sql');

  test('detail hides a receipt generated before the latest settlement change', () {
    final detail = _lastFunctionBlock(inquirySql, 'sales.get_sales_order_detail');
    final start = detail.indexOf('into v_current_receipt_id');
    final lookup = detail.substring(start, detail.indexOf('limit 1;', start));
    expect(lookup, contains("r.status = 'generated'"));
    expect(lookup, contains('from sales.sales_order_settlements s'));
    expect(lookup, contains('s.sales_order_id = r.sales_order_id'));
    expect(lookup, contains('s.updated_at > r.generated_at'));
    expect(lookup, contains('and not exists ('));
  });

  test('generate scopes the idempotency key to the settlement version', () {
    final receipt = _lastFunctionBlock(inquirySql, 'sales.generate_sales_receipt');
    expect(receipt, contains('v_idem_key text;'));
    expect(
      receipt,
      contains("v_idem_key := trim(p_idempotency_key) || ':s' || v_settlement.version;"),
    );
    expect(
      receipt,
      contains(
        "v_idem := sales._begin_sales_idempotency(\n"
        "    p_tenant_id, 'generate_sales_receipt', v_idem_key, p_payload_hash);",
      ),
    );
    expect(
      receipt,
      contains("'generate_sales_receipt',\n    v_idem_key,\n    'succeeded',"),
    );
    expect(receipt, isNot(contains('trim(p_idempotency_key),')));
    // Settlement must be loaded (and locked) before the key is derived.
    expect(
      receipt.indexOf('select * into v_settlement from sales.sales_order_settlements'),
      lessThan(receipt.indexOf('v_idem_key :=')),
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
