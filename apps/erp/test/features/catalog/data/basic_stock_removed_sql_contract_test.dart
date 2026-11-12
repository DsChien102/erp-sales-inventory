import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Directory _findRepoRoot() {
  var dir = Directory.current.absolute;
  while (true) {
    final candidate = File('${dir.path}/supabase/migrations/REGISTRY.yaml');
    if (candidate.existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError(
        'Cannot find repo root from ${Directory.current.path}',
      );
    }
    dir = parent;
  }
}

String _lastFunctionBlock(String sql, String fnName) {
  final marker = 'create or replace function catalog.$fnName(';
  final start = sql.lastIndexOf(marker);
  expect(
    start,
    isNot(-1),
    reason: 'Missing `$marker`',
  );
  final end = sql.indexOf(r'$$;', start);
  expect(
    end,
    isNot(-1),
    reason: 'Missing closing `\$\$;` for `catalog.$fnName`',
  );
  return sql.substring(start, end + 3);
}

void main() {
  late Directory root;

  String readMigration(String filename) =>
      File('${root.path}/supabase/migrations/$filename').readAsStringSync();

  setUpAll(() {
    root = _findRepoRoot();
  });

  test('catalog_no_basic_stock_refs: table 2.6 final function blocks drop basic-stock references', () {
    const targets = <({String fn, String file})>[
      (
        fn: 'search_products',
        file: '20260805003_catalog_search_products_summary_counts.sql',
      ),
      (
        fn: 'get_product_control_center',
        file: '20260725019_catalog_search_pcc_price_after_vat.sql',
      ),
      (
        fn: 'find_product_by_barcode',
        file: '20260725019_catalog_search_pcc_price_after_vat.sql',
      ),
      (
        fn: '_product_operational_facts',
        file: '20260722001_catalog_pending_automatic_price_bands.sql',
      ),
      (
        fn: 'create_guided_product',
        file: '20260722001_catalog_pending_automatic_price_bands.sql',
      ),
      (
        fn: '_refresh_product_operational_facts',
        file: '20260714006_catalog_patch_product_readiness_facts_schema.sql',
      ),
      (
        fn: '_product_readiness_is_ready',
        file: '20260830004_catalog_align_ready_to_sell_exclude_images.sql',
      ),
      (
        fn: '_readiness_blockers_from_facts',
        file: '20260709005_catalog_units.sql',
      ),
      (
        fn: '_refresh_product_readiness',
        file: '20260709010_catalog_product_profile_maintenance.sql',
      ),
      (
        fn: '_product_readiness_summary_json',
        file: '20260709014_catalog_custom_field_values.sql',
      ),
      (
        fn: '_product_deletion_issues',
        file: '20260712003_catalog_rename_basic_stock_quantity_base.sql',
      ),
      (
        fn: '_product_business_status_warnings',
        file: '20260712003_catalog_rename_basic_stock_quantity_base.sql',
      ),
    ];

    final forbiddenPatterns = <({String label, RegExp pattern})>[
      (label: 'product_stock_profiles', pattern: RegExp('product_stock_profiles')),
      (
        // Keeps the legacy parameter `p_basic_stock_quantity_base` on
        // `create_guided_product` while banning `basic_stock_quantity_base`
        // column and `set_basic_stock_quantity_base` calls.
        label: 'basic_stock_quantity_base',
        pattern: RegExp(r'\bbasic_stock_quantity_base\b|set_basic_stock_quantity_base'),
      ),
      (label: 'fact_has_stock', pattern: RegExp('fact_has_stock')),
      (label: 'fact_stock_mode', pattern: RegExp('fact_stock_mode')),
      (label: 'missing_stock', pattern: RegExp('missing_stock')),
      (
        label: 'pending_stock_from_inventory',
        pattern: RegExp('pending_stock_from_inventory'),
      ),
    ];

    for (final target in targets) {
      final block = _lastFunctionBlock(readMigration(target.file), target.fn);
      for (final forbidden in forbiddenPatterns) {
        expect(
          forbidden.pattern.hasMatch(block),
          isFalse,
          reason:
              'catalog.${target.fn} in ${target.file} still contains ${forbidden.label}',
        );
      }
    }

    final guidedBlock = _lastFunctionBlock(
      readMigration('20260722001_catalog_pending_automatic_price_bands.sql'),
      'create_guided_product',
    );
    expect(
      guidedBlock,
      contains("validation_exception: basic stock removed"),
    );
    expect(
      guidedBlock,
      isNot(contains('catalog.product.manage_stock')),
    );
  });

  test('facts_keep_columns: _product_operational_facts keeps has_stock and stock_mode return columns', () {
    final factsBlock = _lastFunctionBlock(
      readMigration('20260722001_catalog_pending_automatic_price_bands.sql'),
      '_product_operational_facts',
    );
    final returnsStart = factsBlock.indexOf('returns table');
    final asStart = factsBlock.indexOf(r'as $$', returnsStart);
    final returnsSlice = factsBlock.substring(returnsStart, asStart);
    expect(returnsSlice, contains('has_stock boolean'));
    expect(returnsSlice, contains('stock_mode text'));
  });

  test('drop_migration_order: 20261116002 drops trigger before tables and removes all 6 basic-stock artifacts', () {
    final file = File(
      '${root.path}/supabase/migrations/20261116002_catalog_drop_basic_stock.sql',
    );
    expect(file.existsSync(), isTrue);
    final sql = file.readAsStringSync().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    final triggerIdx = sql.indexOf(
      'drop trigger if exists trg_product_stock_profiles_refresh_operational_facts on catalog.product_stock_profiles',
    );
    final trgFnIdx = sql.indexOf(
      'drop function if exists catalog._trg_product_stock_profiles_refresh_operational_facts()',
    );
    final setFnIdx = sql.indexOf(
      'catalog.set_basic_stock_quantity_base(uuid, uuid, text, numeric)',
    );
    final adjFnIdx = sql.indexOf(
      'catalog.adjust_basic_stock(uuid, uuid, numeric, text, numeric)',
    );
    final histFnIdx = sql.indexOf(
      'catalog.get_product_stock_history(uuid, uuid, int)',
    );
    final dropFactColsIdx = sql.indexOf('drop column if exists fact_has_stock');
    final dropFactModeIdx = sql.indexOf('drop column if exists fact_stock_mode');
    final dropTablesIdx = sql.indexOf('drop table if exists catalog.product_stock_movements, catalog.product_stock_profiles');

    expect(triggerIdx, isNonNegative);
    expect(trgFnIdx, isNonNegative);
    expect(setFnIdx, isNonNegative);
    expect(adjFnIdx, isNonNegative);
    expect(histFnIdx, isNonNegative);
    expect(dropFactColsIdx, isNonNegative);
    expect(dropFactModeIdx, isNonNegative);
    expect(dropTablesIdx, isNonNegative);
    expect(triggerIdx, lessThan(trgFnIdx));
    expect(triggerIdx, lessThan(dropTablesIdx));
  });

  test('readiness_ignores_stock: _product_readiness_is_ready removes p_has_stock check', () {
    final block = _lastFunctionBlock(
      readMigration('20260830004_catalog_align_ready_to_sell_exclude_images.sql'),
      '_product_readiness_is_ready',
    );
    expect(block, isNot(contains('p_has_stock, false')));
  });
}

