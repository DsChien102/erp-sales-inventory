import 'dart:io';

import 'package:test/test.dart';

void main() {
  late final String sql;
  late final String precheckSql;

  setUpAll(() {
    sql = _draftSqlFile().readAsStringSync();
    precheckSql = _functionSql(sql, 'sales.precheck_sales_order_checkout');
  });

  test('declares rebuild checkout precheck owner and frozen signature', () {
    expect(sql, contains('-- Kind: draft'));
    expect(sql, contains('-- Intent: sales_checkout_rpcs'));
    expect(sql, contains('create or replace function sales.precheck_sales_order_checkout'));
    expect(sql, contains('p_query_id uuid'));
    expect(sql, contains('p_payment_intents jsonb'));
    expect(sql, contains('p_payment_due_date date default null'));
    expect(sql, contains('p_expected_source_version'));
    expect(
      sql,
      contains(
        "sales._assert_sales_actor(p_tenant_id, p_actor_id, p_store_id, 'sales.checkout.create')",
      ),
    );
    expect(sql, contains("iam.has_permission(p_tenant_id, 'sales.payment.record')"));
    expect(sql, contains("v_line -> 'unit_price' ->> 'amount_minor'"));
    expect(sql, contains("'canFinalize'"));
    expect(sql, contains("'receivableRequirement'"));
    expect(sql, contains('v_paid_total_minor'));
    expect(sql, contains('v_remaining_minor'));
    expect(sql, contains('set search_path = sales, iam, public, pg_temp'));
  });

  test('checkout no longer depends on retired store policy', () {
    expect(sql, isNot(contains('create table')));
    expect(sql, isNot(contains('sales.checkout_store_policies')));
    final schemaSql = _schemaDraftSqlFile().readAsStringSync();
    expect(
      schemaSql,
      isNot(contains('create table if not exists sales.checkout_store_policies')),
    );
  });

  test('precheck revalidates catalog sellable state for checkout lines', () {
    expect(precheckSql, contains('PRODUCT_NOT_SELLABLE'));
    expect(precheckSql, contains('catalog.products'));
    expect(precheckSql, contains('catalog.product_units'));
    expect(
      precheckSql,
      contains("p.business_status = 'active'::catalog.product_business_status"),
    );
    expect(precheckSql, contains('p.is_ready_to_sell = true'));
    expect(precheckSql, contains('pu.is_active = true'));
    expect(precheckSql, contains("Sản phẩm đã ngừng bán. Vui lòng quay lại đơn."));
    expect(precheckSql, contains("'field', 'lines[' || (v_line_index - 1)::text || ']'"));
  });
}

File _draftSqlFile() {
  const relativePath =
      'supabase/migrations/20260830008_sales_checkout_rpcs.sql';
  final candidates = [
    File(relativePath),
    File('../../../$relativePath'),
    File('../../../../$relativePath'),
  ];
  for (final candidate in candidates) {
    if (candidate.existsSync()) {
      return candidate;
    }
  }
  return candidates.first;
}

File _schemaDraftSqlFile() {
  const relativePath =
      'supabase/migrations/20260830005_sales_rebuild_schema.sql';
  final candidates = [
    File(relativePath),
    File('../../../$relativePath'),
    File('../../../../$relativePath'),
  ];
  for (final candidate in candidates) {
    if (candidate.existsSync()) {
      return candidate;
    }
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
