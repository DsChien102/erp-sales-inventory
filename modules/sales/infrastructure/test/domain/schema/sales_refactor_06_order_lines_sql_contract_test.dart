import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Sales refactor bảng 6 `sales.sales_order_lines`
/// (docs/superpowers/specs/sales-schema-refactor/06-sales-order-lines.md).
void main() {
  final schemaSql = _readMigration('20260830005_sales_rebuild_schema.sql');
  final checkoutSql = _readMigration('20260830008_sales_checkout_rpcs.sql');
  final inquirySql = _readMigration('20260830010_sales_inquiry_receipt_rpcs.sql');

  test('order lines drop pricing/tax snapshots and own their checks', () {
    final start = schemaSql.indexOf('create table if not exists sales.sales_order_lines (');
    final table = schemaSql.substring(start, schemaSql.indexOf('\n);', start));
    expect(table, isNot(contains('pricing_snapshot')));
    expect(table, isNot(contains('tax_snapshot')));
    expect(table, contains('constraint sales_order_lines_base_qty_positive'));
    expect(table, contains('constraint sales_order_lines_commercial_balance'));
    expect(schemaSql, isNot(contains('alter table sales.sales_order_lines')));
  });

  test('finalize no longer copies lines into sales_context_snapshot', () {
    final finalize = _lastFunctionBlock(checkoutSql, 'sales.finalize_sales_order');
    expect(finalize, isNot(contains('v_normalized_lines')));
    final snapStart = finalize.indexOf('v_normalized_commercial_snapshot := jsonb_build_object(');
    final snapshot = finalize.substring(snapStart, finalize.indexOf('\n    );', snapStart));
    expect(snapshot, isNot(contains("'lines'")));
    final insertStart = finalize.indexOf('insert into sales.sales_order_lines(');
    final insert = finalize.substring(insertStart, finalize.indexOf('end loop;', insertStart));
    expect(insert, isNot(contains('pricing_snapshot')));
    expect(insert, contains('product_snapshot, product_unit_snapshot, line_note'));
  });

  test('order lines payload helper builds lines from the table', () {
    final helper = _lastFunctionBlock(inquirySql, 'sales._sales_order_lines_payload');
    expect(helper, contains('language sql'));
    expect(helper, contains('from sales.sales_order_lines line'));
    expect(helper, contains('order by line.line_sequence, line.id'));
    expect(
      inquirySql,
      contains(
        'revoke all on function sales._sales_order_lines_payload(uuid, uuid, text) from public, anon, authenticated;',
      ),
    );
    expect(
      inquirySql.indexOf('create or replace function sales._sales_order_lines_payload('),
      lessThan(inquirySql.indexOf('create or replace function sales.get_sales_order(')),
    );
  });

  test('detail reads lines through the helper; receipt reads table lines', () {
    final detail = _lastFunctionBlock(inquirySql, 'sales.get_sales_order_detail');
    expect(
      detail,
      contains("'lines', sales._sales_order_lines_payload(v_order.tenant_id, v_order.id, v_order.currency_code),"),
    );
    // Receipt nets return/exchange lines via _sales_receipt_lines_payload
    // (see sales_receipt_current_lines_sql_contract_test.dart).
    final receiptHelper = _lastFunctionBlock(inquirySql, 'sales._sales_receipt_lines_payload');
    expect(receiptHelper, contains('from sales.sales_order_lines l'));
    expect(inquirySql, isNot(contains("sales_context_snapshot -> 'lines'")));
  });

  test('return/exchange no longer falls back to snapshot lines', () {
    final rxSql = _readMigration('20260830012_sales_return_exchange_session_rpcs.sql');
    expect(rxSql, isNot(contains('sales_context_snapshot')));
    final returnable = _lastFunctionBlock(rxSql, 'sales.get_returnable_order_lines');
    expect(
      returnable,
      contains(
        "'displayName', coalesce(\n"
        "          nullif(btrim(l.product_snapshot ->> 'displayName'), ''),\n"
        '          l.product_id::text\n'
        '        )',
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
