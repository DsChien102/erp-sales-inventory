import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('source type uses a database enum while RPC wire stays text', () {
    final repoRoot = _findRepoRoot();
    final schemaSql = File(
      '${repoRoot.path}/supabase/migrations/_drafts/'
      'catalog_price_band_calculation_modes_schema.sql',
    ).readAsStringSync();
    final rpcSql = File(
      '${repoRoot.path}/supabase/migrations/_drafts/'
      'catalog_price_band_calculation_modes_rpcs.sql',
    ).readAsStringSync();

    expect(
      schemaSql,
      contains(
        "create type catalog.price_band_source_type as enum "
        "('ruleBased', 'customConfig', 'manual')",
      ),
    );
    expect(
      schemaSql,
      contains(
        'alter column source_type type catalog.price_band_source_type\n'
        '    using source_type::text::catalog.price_band_source_type',
      ),
    );
    expect(
      schemaSql,
      isNot(contains('product_unit_price_bands_source_type_check\n    check')),
      reason: 'The enum replaces the old source_type value check constraint.',
    );

    final setDefinition = _functionDefinition(
      rpcSql,
      'set_product_unit_price_band',
    );
    expect(setDefinition, contains("p_source_type text default 'manual'"));
    expect(
      setDefinition,
      contains('p_source_type::catalog.price_band_source_type'),
      reason: 'Text input must be cast at the persistence boundary.',
    );

    final listDefinition = _functionDefinition(
      rpcSql,
      'list_product_unit_price_bands',
    );
    expect(listDefinition, contains('source_type text'));
    expect(
      listDefinition,
      contains('pb.source_type::text'),
      reason: 'The RPC must keep returning the existing text wire value.',
    );
  });

  test('apply store price rule hotfix resolves output-column ambiguity', () {
    final repoRoot = _findRepoRoot();
    final hotfix = File(
      '${repoRoot.path}/supabase/migrations/_drafts/'
      'catalog_apply_store_price_rule_ambiguous_columns_hotfix.sql',
    );

    expect(
      hotfix.existsSync(),
      isTrue,
      reason: 'The focused SQL hotfix must be available for promotion/application.',
    );
    if (!hotfix.existsSync()) return;

    final sql = hotfix.readAsStringSync();
    expect(sql, contains('-- Kind: surgical'));
    expect(sql, contains('-- Touches: apply_store_price_rule'));
    expect(
      RegExp(r'create or replace function catalog\.').allMatches(sql),
      hasLength(1),
      reason: 'The hotfix must redefine only apply_store_price_rule.',
    );
    expect(
      _functionDefinition(sql, 'apply_store_price_rule'),
      contains(
        r'as $$'
        '\n#variable_conflict use_column',
      ),
    );
  });

  test('price band upserts resolve output-column names as table columns', () {
    final repoRoot = _findRepoRoot();
    final sql = File(
      '${repoRoot.path}/supabase/migrations/_drafts/'
      'catalog_price_band_calculation_modes_rpcs.sql',
    ).readAsStringSync();

    for (final functionName in <String>[
      'set_product_unit_price_band',
      'apply_store_price_rule',
    ]) {
      final definition = _functionDefinition(sql, functionName);
      expect(
        definition,
        contains(
          r'as $$'
          '\n#variable_conflict use_column',
        ),
        reason: '$functionName must prefer table columns in its ON CONFLICT target',
      );
    }
  });

  test('direct price band mutations record structured before and after snapshots', () {
    final repoRoot = _findRepoRoot();
    final draft = File(
      '${repoRoot.path}/supabase/migrations/_drafts/'
      'catalog_product_price_band_change_history_direct.sql',
    );

    expect(
      draft.existsSync(),
      isTrue,
      reason: 'The direct price-band history draft must be available.',
    );
    if (!draft.existsSync()) return;

    final sql = draft.readAsStringSync();
    expect(sql, contains('-- Kind: patch'));
    expect(
      sql,
      contains(
        '-- Touches: _record_product_price_band_change, set_initial_price_band, '
        'set_product_unit_price_band, apply_store_price_rule, '
        'create_guided_product, get_product_change_history',
      ),
    );

    final helper = _functionDefinition(
      sql,
      '_record_product_price_band_change',
    );
    expect(helper, contains("'price_band_change'"));
    expect(helper, contains("'source_type', p_before_source_type"));
    expect(helper, contains("'list_price', p_before_list_price"));
    expect(helper, contains("'floor_price', p_before_floor_price"));
    expect(helper, contains("'source_type', p_after_source_type"));
    expect(helper, contains("'list_price', p_after_list_price"));
    expect(helper, contains("'floor_price', p_after_floor_price"));
    expect(helper, isNot(contains("'list_markup_ratio'")));
    expect(helper, isNot(contains("'floor_markup_ratio'")));
    expect(helper, contains('is not distinct from'));

    final initial = _functionDefinition(sql, 'set_initial_price_band');
    expect(initial, contains('p_before_source_type => null'));
    expect(initial, contains("p_after_source_type => 'manual'"));

    final setBand = _functionDefinition(sql, 'set_product_unit_price_band');
    expect(setBand, contains('v_before_source_type text'));
    expect(setBand, contains('for update'));
    expect(setBand, contains("p_trigger => 'direct'"));

    final applyRule = _functionDefinition(sql, 'apply_store_price_rule');
    expect(applyRule, contains('v_before_source_type text'));
    expect(applyRule, contains('for update'));
    expect(applyRule, contains("p_after_source_type => 'ruleBased'"));

    final guided = _functionDefinition(sql, 'create_guided_product');
    expect(guided, contains('p_price_band_source_type text default null'));
    expect(guided, contains('p_list_markup_ratio numeric default null'));
    expect(guided, contains('p_floor_markup_ratio numeric default null'));
    expect(guided, contains("when 'customConfig' then"));
    expect(guided, contains("when 'ruleBased' then"));

    final history = _functionDefinition(sql, 'get_product_change_history');
    expect(history, contains("h.payload -> 'price_band_change'"));
    expect(history, contains('and not v_can_view_pricing then null'));
  });

  test('automatic recalculation records only changed eligible price bands', () {
    final repoRoot = _findRepoRoot();
    final draft = File(
      '${repoRoot.path}/supabase/migrations/_drafts/'
      'catalog_product_price_band_change_history_recalculation.sql',
    );

    expect(
      draft.existsSync(),
      isTrue,
      reason: 'The automatic price-band history draft must be available.',
    );
    if (!draft.existsSync()) return;

    final sql = draft.readAsStringSync();
    expect(sql, contains('-- Kind: patch'));
    expect(
      sql,
      contains(
        '-- Touches: _product_change_history_category, '
        '_recalculate_product_price_bands, set_manual_base_price, '
        'set_store_price_rule',
      ),
    );
    expect(sql, contains("'basePriceChanged'"));
    expect(sql, contains("'storeRuleChanged'"));

    final recalculate = _functionDefinition(
      sql,
      '_recalculate_product_price_bands',
    );
    expect(recalculate, contains('p_trigger text'));
    expect(recalculate, contains('is distinct from'));
    expect(recalculate, contains("p_action => 'recalculate_product_unit_price_band'"));
    expect(recalculate, contains("pb.source_type = 'customConfig'"));
    expect(recalculate, contains("pb.source_type = 'ruleBased'"));
    expect(recalculate, isNot(contains("pb.source_type = 'manual'")));

    final setBasePrice = _functionDefinition(sql, 'set_manual_base_price');
    expect(setBasePrice, contains("p_trigger => 'basePriceChanged'"));

    final setStoreRule = _functionDefinition(sql, 'set_store_price_rule');
    expect(setStoreRule, contains("p_trigger => 'storeRuleChanged'"));
  });
}

String _functionDefinition(String sql, String functionName) {
  final start = sql.indexOf(
    'create or replace function catalog.$functionName(',
  );
  if (start < 0) {
    throw StateError('Could not locate catalog.$functionName');
  }
  final end = sql.indexOf(r'$$;', start);
  if (end < 0) {
    throw StateError('Could not locate the end of catalog.$functionName');
  }
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
