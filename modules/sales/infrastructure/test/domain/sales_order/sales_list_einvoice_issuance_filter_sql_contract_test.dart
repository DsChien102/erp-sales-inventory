import 'dart:io';

import 'package:test/test.dart';

void main() {
  late final String sql;

  setUpAll(() {
    sql = _draftSqlFile().readAsStringSync();
  });

  test('replaces list and search with issued-invoice filter', () {
    expect(sql, contains('-- Kind: patch'));
    expect(sql, contains('-- Intent: sales_list_einvoice_issuance_filter'));
    expect(sql, contains('-- Touches: sales.list_sales_orders, sales.search_sales_orders'));
    expect(sql, contains('create or replace function sales.list_sales_orders('));
    expect(sql, contains('create or replace function sales.search_sales_orders('));
  });

  test('list derives delivered from electronic_invoices and drops the notRequired-only gate', () {
    final listSql = _functionSql(sql, 'sales.list_sales_orders');
    expect(listSql, isNot(contains("'notRequired'::text as e_invoice_status")));
    expect(listSql, isNot(contains("or list_sales_orders.e_invoice_status = 'notRequired'")));
    expect(listSql, contains('from einvoice.electronic_invoices ei'));
    expect(listSql, contains("then 'delivered'"));
    expect(listSql, contains("else 'notRequired'"));
    expect(listSql, contains("list_sales_orders.e_invoice_status is null"));
    expect(listSql, contains("list_sales_orders.e_invoice_status = 'delivered'"));
    expect(listSql, contains("list_sales_orders.e_invoice_status = 'queued'"));
    expect(listSql, contains('and not exists ('));
    expect(
      listSql,
      contains(
        "'eInvoicePending', (select count(*) filter (where filtered.e_invoice_status = 'notRequired') from filtered)",
      ),
    );
  });

  test('search uses the same issued-invoice predicate', () {
    final searchSql = _functionSql(sql, 'sales.search_sales_orders');
    expect(searchSql, isNot(contains("'notRequired'::text as e_invoice_status")));
    expect(searchSql, isNot(contains("or search_sales_orders.e_invoice_status = 'notRequired'")));
    expect(searchSql, contains('from einvoice.electronic_invoices ei'));
    expect(searchSql, contains("search_sales_orders.e_invoice_status = 'delivered'"));
    expect(searchSql, contains("search_sales_orders.e_invoice_status = 'queued'"));
    expect(searchSql, contains('and not exists ('));
    expect(
      searchSql,
      contains(
        "'eInvoicePending', (select count(*) filter (where filtered.e_invoice_status = 'notRequired') from filtered)",
      ),
    );
  });
}

File _draftSqlFile() {
  const relativePath =
      'supabase/migrations/_drafts/021_sales_list_einvoice_issuance_filter.sql';
  final candidates = [
    File(relativePath),
    File('../../../$relativePath'),
    File('../../../../$relativePath'),
  ];
  for (final candidate in candidates) {
    if (candidate.existsSync()) return candidate;
  }
  return candidates.first;
}

String _functionSql(String sql, String function) {
  final start = sql.indexOf('create or replace function $function(');
  if (start < 0) throw StateError('Missing function $function.');
  final end = sql.indexOf('\n\$\$;', start);
  if (end < 0) throw StateError('Missing terminator for $function.');
  return sql.substring(start, end + '\n\$\$;'.length);
}
