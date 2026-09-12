import 'dart:io';
import 'package:test/test.dart';

void main() {
  late final String detailSql;
  setUpAll(() {
    final path = 'supabase/migrations/_drafts/010_sales_inquiry_receipt_rpcs.sql';
    final sql = File(path).existsSync()
        ? File(path).readAsStringSync()
        : File('../../../$path').readAsStringSync();
    final s = sql.indexOf('create or replace function sales.get_sales_order_detail(');
    final e = sql.indexOf('\n\$\$;', s);
    detailSql = sql.substring(s, e);
  });

  test('detail exposes derived current holdings (currentLines)', () {
    expect(detailSql, contains("'currentLines'"));
    // Union of original lines and confirmed exchange lines, net of returns.
    expect(detailSql, contains("line_role = 'exchange'"));
    expect(detailSql, contains('source_exchange_line_id'));
    expect(detailSql, contains("'heldQuantity'"));
    expect(detailSql, contains("'source'"));
  });

  test('current holdings stays under order.view permission (no return_exchange.create)', () {
    expect(detailSql, isNot(contains("'sales.return_exchange.create'")));
  });
}
