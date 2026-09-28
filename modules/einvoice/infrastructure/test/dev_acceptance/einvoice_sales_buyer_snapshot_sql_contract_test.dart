import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String sql;

  setUpAll(() {
    var dir = Directory.current;
    while (!Directory('${dir.path}/supabase/migrations/_drafts').existsSync()) {
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
    final file = File(
      '${dir.path}/supabase/migrations/_drafts/'
      '017_sales_buyer_invoice_snapshot.sql',
    );
    sql = file.existsSync() ? file.readAsStringSync() : '';
  });

  group('Sales buyer invoice snapshot SQL contract', () {
    test('checkout persists buyer_tax_snapshot from the client snapshot', () {
      expect(
        sql,
        contains('create or replace function sales.finalize_sales_order('),
      );
      expect(sql, contains('buyer_tax_snapshot'));
      expect(sql, contains("'buyerType'"));
      expect(sql, contains("'legalName'"));
      expect(sql, contains("'address'"));
      expect(sql, contains("'email'"));
    });

    test('sales never reaches into the partner schema', () {
      expect(
        sql,
        isNot(contains('partner.')),
        reason: 'checkout must not depend on Partner availability (cách A)',
      );
    });

    test('finalize is based on the theme5 order schema (dropped columns gone)', () {
      for (final dropped in ['business_time', 'customer_snapshot', 'pricing_summary_snapshot', 'sales_shift_id', 'reference_code']) {
        expect(sql, isNot(contains(dropped)), reason: dropped);
      }
      expect(sql, contains("'invoiceLegalName'"));
      expect(sql, contains("'Commercial customer buyerType is invalid.'"));
    });
  });
}
