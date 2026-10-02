import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('detail current lines expose net unit price and original price', () {
    var dir = Directory.current.absolute;
    while (!Directory('${dir.path}/supabase/migrations').existsSync()) {
      dir = dir.parent;
    }
    final sql = File('${dir.path}/supabase/migrations/20260830010_sales_inquiry_receipt_rpcs.sql').readAsStringSync();
    final start = sql.lastIndexOf('create or replace function sales.get_sales_order_detail(');
    final fn = sql.substring(start, sql.indexOf(r'$$;', start));
    expect(fn, contains("'unitPrice', jsonb_build_object('amountMinor', round(l.line_total_minor::numeric * 1000000 / l.quantity_micros)::bigint, 'currencyCode', v_order.currency_code),"));
    expect(fn, contains("'originalUnitPrice', case when l.discount_amount_minor > 0"));
  });
}
