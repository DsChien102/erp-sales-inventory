import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('sellable lookup draft is tenant/store guarded and returns only authoritative facts', () {
    final draft = File(
      '${_findRepoRoot().path}/supabase/migrations/_drafts/'
      '002_catalog_sales_sellable_lookup_group_a.sql',
    );

    expect(draft.existsSync(), isTrue);
    if (!draft.existsSync()) return;

    final sql = draft.readAsStringSync();
    expect(sql, contains('-- Kind: draft'));
    expect(sql, contains('-- Intent: th05_group_a_catalog_sales_sellable_lookup'));
    expect(sql, contains('-- Touches:'));

    for (final functionName in <String>[
      'search_sellable_products',
      'resolve_sellable_barcode',
      'list_sellable_product_units',
    ]) {
      final definition = _functionDefinition(sql, functionName);
      expect(definition, contains('auth.uid() is null'));
      expect(definition, contains('iam.memberships'));
      expect(definition, contains('iam.can_access_store('));
      expect(definition, contains('iam.stores'));
      expect(definition, contains("store.status = 'active'"));
      expect(definition, contains('store.tenant_id = p_tenant_id'));
      expect(definition, contains('p.tenant_id = p_tenant_id'));
      expect(definition, contains('p.is_ready_to_sell = true'));
      expect(definition, contains('pu.is_active = true'));
      expect(definition, contains("p.business_status = 'active'::catalog.product_business_status"));
      expect(definition, contains('available_stock_micros'));
      expect(definition, contains('product_stock_profiles'));
      expect(definition, contains('basic_stock_quantity_base'));
      expect(definition, contains('conversion_rate_to_base'));
      expect(definition, isNot(contains("'available_stock_micros', null::bigint")));
      expect(definition, contains("'barcode', p.barcode"));
      expect(definition, isNot(contains('productId::base')));
    }

    final barcode = _functionDefinition(sql, 'resolve_sellable_barcode');
    expect(barcode, contains('catalog._normalize_product_barcode(p_barcode)'));
    expect(barcode, contains('p.barcode = v_barcode'));
    _expectMatchedProductsProjectsTradeName(barcode);
    expect(barcode, contains("'trade_name', p.trade_name"));
    expect(barcode, contains('order by p.name asc, p.id asc'));

    final search = _functionDefinition(sql, 'search_sellable_products');
    _expectMatchedProductsProjectsTradeName(search);
    expect(search, contains("'trade_name', p.trade_name"));
    expect(search, contains('p.search_text like'));
    expect(search, contains('p.id::text = btrim(p_keyword)'));
    expect(search, contains('p.sku = v_sku'));
    expect(search, contains('p.barcode = v_barcode'));
    expect(search, contains('order by p.name asc, p.id asc'));

    final units = _functionDefinition(sql, 'list_sellable_product_units');
    expect(units, contains('pu.product_id = p_product_id'));
    expect(units, contains('pu.tenant_id = p_tenant_id'));
    expect(units, contains('order by pu.is_base_unit desc, pu.unit_name asc, pu.id asc'));
  });
}

void _expectMatchedProductsProjectsTradeName(String definition) {
  expect(
    definition,
    matches(
      RegExp(
        r'with\s+matched_products\s+as\s*\(\s*select\s+'
        r'p\.id,\s*p\.tenant_id,\s*p\.name,\s*p\.trade_name,',
      ),
    ),
  );
}

String _functionDefinition(String sql, String functionName) {
  final start = sql.indexOf(
    'create or replace function catalog.$functionName(',
  );
  if (start < 0) {
    throw StateError('Could not locate catalog.$functionName.');
  }
  final end = sql.indexOf(r'$$;', start);
  if (end < 0) {
    throw StateError('Could not locate the end of catalog.$functionName.');
  }
  return sql.substring(start, end + 3);
}

Directory _findRepoRoot() {
  var current = Directory.current.absolute;
  while (!Directory('${current.path}/supabase/migrations').existsSync()) {
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not locate the Vet45 workspace root.');
    }
    current = parent;
  }
  return current;
}
