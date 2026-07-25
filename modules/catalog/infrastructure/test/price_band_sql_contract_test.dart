import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('guided create forwards optional note atomically', () {
    final repoRoot = _findRepoRoot();
    final migration = File(
      '${repoRoot.path}/supabase/migrations/'
      '20260722001_catalog_pending_automatic_price_bands.sql',
    );

    expect(
      migration.existsSync(),
      isTrue,
      reason: 'The pending automatic price bands migration must be available.',
    );
    if (!migration.existsSync()) return;

    final sql = migration.readAsStringSync();
    expect(sql, contains('-- Kind: patch'));
    expect(sql, contains('-- Intent: catalog_pending_automatic_price_bands'));
    expect(
      sql,
      contains(
        '-- Touches: create_guided_product, set_product_unit_price_band, '
        '_recalculate_product_price_bands, _product_operational_facts',
      ),
    );

    final guided = _functionDefinition(sql, 'create_guided_product');
    expect(guided, contains('p_note text default null'));
    expect(guided, contains('p_note => p_note'));
    expect(guided, contains('p_list_price_before_vat => 0'));
    expect(guided, contains("p_source_type => 'customConfig'"));
    expect(
      guided,
      isNot(contains('or p_base_price_after_vat is null')),
    );
  });

  test(
    'pending automatic bands persist as zero and materialize from current sources',
    () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/'
        '20260722001_catalog_pending_automatic_price_bands.sql',
      );

      expect(
        migration.existsSync(),
        isTrue,
        reason: 'The pending automatic price bands migration must be available.',
      );
      if (!migration.existsSync()) return;

      final sql = migration.readAsStringSync();
      expect(sql, contains('-- Kind: patch'));
      expect(sql, contains('-- Intent: catalog_pending_automatic_price_bands'));
      expect(sql, contains('product_unit_price_bands_calculation_source_check'));
      expect(sql, contains('p_note text default null'));
      expect(sql, contains('p_note => p_note'));
      expect(
        sql,
        contains(
          '-- Touches: create_guided_product, set_product_unit_price_band, '
          '_recalculate_product_price_bands, _product_operational_facts',
        ),
      );

      final guided = _functionDefinition(sql, 'create_guided_product');
      expect(guided, contains("when 'ruleBased' then"));
      expect(guided, contains("when 'customConfig' then"));
      expect(guided, contains('p_list_price_before_vat => 0'));
      expect(guided, contains('p_floor_price_before_vat => 0'));

      final setBand = _functionDefinition(sql, 'set_product_unit_price_band');
      expect(setBand, contains('when v_base_price is null then 0'));
      expect(
        setBand,
        isNot(
          contains(
            "raise exception 'validation_exception: use apply_store_price_rule'",
          ),
        ),
      );

      final recalculate = _functionDefinition(
        sql,
        '_recalculate_product_price_bands',
      );
      expect(recalculate, contains("pb.source_type = 'ruleBased'"));
      expect(recalculate, contains("pb.source_type = 'customConfig'"));
      expect(recalculate, isNot(contains("pb.source_type = 'manual'")));
      expect(recalculate, contains('r.tenant_id = pb.tenant_id'));
      expect(recalculate, contains("r.status = 'active'"));
      expect(recalculate, isNot(contains('on sr.id = pb.store_price_rule_id')));

      final facts = _functionDefinition(sql, '_product_operational_facts');
      expect(facts, contains('as has_price_band'));
      expect(facts, contains('-- True only when every active unit'));
      expect(facts, contains('pu.is_active = true'));
      expect(facts, contains("pb.source_type = 'manual'"));
      expect(facts, contains("pb.source_type in ('customConfig', 'ruleBased')"));
      expect(facts, contains("r.status = 'active'"));
      expect(
        facts,
        isNot(contains('and bu.is_base_unit = true')),
        reason: 'has_price_band must require every active unit, not only the base unit.',
      );
    },
  );

  test('custom config can stay pending until a base price exists', () {
    final repoRoot = _findRepoRoot();
    final migration = File(
      '${repoRoot.path}/supabase/migrations/'
      '20260721002_catalog_product_price_band_pending_custom_config.sql',
    );

    expect(migration.existsSync(), isTrue);
    if (!migration.existsSync()) return;

    final sql = migration.readAsStringSync();
    expect(sql, contains('-- Kind: patch'));
    expect(sql, contains('-- Touches: set_product_unit_price_band'));
    final overloadCleanupIndex = sql.indexOf(
      "p.proname = 'create_guided_product'",
    );
    final createGuidedProductIndex = sql.indexOf(
      'create or replace function catalog.create_guided_product(',
    );
    expect(
      overloadCleanupIndex,
      greaterThanOrEqualTo(0),
      reason: 'The migration must remove stale RPC overloads.',
    );
    expect(
      overloadCleanupIndex,
      lessThan(createGuidedProductIndex),
      reason: 'Overload cleanup must run before recreating the canonical RPC.',
    );
    expect(sql, contains('pg_get_function_identity_arguments(p.oid)'));
    expect(
      sql,
      contains('alter column list_price_after_vat drop not null'),
    );

    final setBand = _functionDefinition(sql, 'set_product_unit_price_band');
    expect(setBand, isNot(contains("raise exception 'missing_base_price'")));
    expect(setBand, contains('when v_base_price is null then null'));
    expect(setBand, contains('p_list_markup_ratio'));
    expect(setBand, contains('p_floor_markup_ratio'));

    final guided = _functionDefinition(sql, 'create_guided_product');
    expect(
      guided,
      isNot(contains('or p_base_price_after_vat is null')),
    );
    expect(guided, contains('p_list_price_before_vat => null'));
    expect(guided, contains("p_source_type => 'customConfig'"));

    final recalculateSql = File(
      '${repoRoot.path}/supabase/migrations/'
      '20260717008_catalog_product_price_band_change_history_recalculation.sql',
    ).readAsStringSync();
    final recalculate = _functionDefinition(
      recalculateSql,
      '_recalculate_product_price_bands',
    );
    expect(recalculate, contains("pb.source_type = 'customConfig'"));
    expect(recalculate, contains('is distinct from'));
  });

  test('source type uses a database enum while RPC wire stays text', () {
    final repoRoot = _findRepoRoot();
    final schemaSql = File(
      '${repoRoot.path}/supabase/migrations/'
      '20260717004_catalog_price_band_calculation_modes_schema.sql',
    ).readAsStringSync();
    final rpcSql = File(
      '${repoRoot.path}/supabase/migrations/'
      '20260717003_catalog_price_band_calculation_modes_rpcs.sql',
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
      '${repoRoot.path}/supabase/migrations/'
      '20260717002_catalog_apply_store_price_rule_ambiguous_columns_hotfix.sql',
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
      '${repoRoot.path}/supabase/migrations/'
      '20260717003_catalog_price_band_calculation_modes_rpcs.sql',
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
      '${repoRoot.path}/supabase/migrations/'
      '20260717007_catalog_product_price_band_change_history_direct.sql',
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
    expect(guided, contains('v_can_apply_store_rule boolean := false'));
    expect(guided, contains('v_store_price_rule_id uuid'));
    expect(guided, contains("else 'ruleBased'"));
    expect(guided, contains("r.status = 'active'"));
    expect(guided, contains('p_base_price_after_vat is not null'));
    expect(guided, contains('v_store_price_rule_id is not null'));
    expect(guided, contains('if v_can_apply_store_rule then'));
    expect(
      guided,
      contains('p_store_price_rule_id => v_store_price_rule_id'),
    );
    expect(
      guided,
      isNot(contains("when 'ruleBased' then\n      perform 1 from")),
      reason: 'Store pricing must be skipped when prerequisites are missing.',
    );

    final history = _functionDefinition(sql, 'get_product_change_history');
    expect(history, contains("h.payload -> 'price_band_change'"));
    expect(history, contains('and not v_can_view_pricing then null'));
  });

  test('automatic recalculation records only changed eligible price bands', () {
    final repoRoot = _findRepoRoot();
    final draft = File(
      '${repoRoot.path}/supabase/migrations/'
      '20260717008_catalog_product_price_band_change_history_recalculation.sql',
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

  test(
    'set base unit creates pending ruleBased band when product has none',
    () {
      final repoRoot = _findRepoRoot();
      final draft = File(
        '${repoRoot.path}/supabase/migrations/_drafts/'
        'catalog_set_base_unit_pending_rule_based_band.sql',
      );

      expect(
        draft.existsSync(),
        isTrue,
        reason: 'The set-base-unit pending band draft must be available.',
      );
      if (!draft.existsSync()) return;

      final sql = draft.readAsStringSync();
      expect(sql, contains('-- Kind: patch'));
      expect(
        sql,
        contains('-- Intent: catalog_set_base_unit_pending_rule_based_band'),
      );
      expect(sql, contains('-- Touches: set_product_base_unit'));
      expect(
        sql,
        contains(
          '-- Depends on: 20260722001_catalog_pending_automatic_price_bands.sql',
        ),
      );

      final setBaseUnit = _functionDefinition(sql, 'set_product_base_unit');
      expect(
        setBaseUnit,
        contains("catalog.product.manage_pricing"),
      );
      expect(
        setBaseUnit,
        contains('not exists'),
      );
      expect(
        setBaseUnit,
        contains('catalog.product_unit_price_bands'),
      );
      expect(
        setBaseUnit,
        contains('catalog.set_product_unit_price_band'),
      );
      expect(setBaseUnit, contains("p_source_type => 'ruleBased'"));
      expect(setBaseUnit, contains('p_list_price_before_vat => 0'));
      expect(setBaseUnit, contains('p_floor_price_before_vat => 0'));
      // Readiness refresh must run after the optional pending-band insert.
      expect(
        setBaseUnit.indexOf('catalog.set_product_unit_price_band'),
        lessThan(setBaseUnit.indexOf('catalog._product_operational_facts')),
      );
    },
  );
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
