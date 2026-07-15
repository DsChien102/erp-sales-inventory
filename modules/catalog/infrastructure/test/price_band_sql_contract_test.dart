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
