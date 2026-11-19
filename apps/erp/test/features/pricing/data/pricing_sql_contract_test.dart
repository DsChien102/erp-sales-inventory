import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('kept', () {
    test('keeps every RPC the app calls', () {
      final sql = _allMigrationsSql();
      const appPricingRpcNames = [
        'search_customer_price_rules',
        'get_customer_price_rule_detail',
        'get_customer_price_rule_history',
        'create_customer_price_rule',
        'update_customer_price_rule',
        'disable_customer_price_rule',
        'precheck_customer_price_rule_reenable',
        'reenable_customer_price_rule',
        'resolve_applicable_customer_price_rule',
        'preview_sales_working_state_pricing',
        'evaluate_sales_manual_price',
      ];

      for (final rpc in appPricingRpcNames) {
        expect(
          _definesFn(sql, 'pricing', rpc),
          isTrue,
          reason: 'Expected pricing.$rpc to be defined in migrations.',
        );
      }
    });

    test('keeps RPCs TH-04 keeps unused', () {
      final sql = _allMigrationsSql();

      expect(
        _definesFn(sql, 'pricing', 'delete_customer_price_rule'),
        isTrue,
        reason: 'TH-04 keeps delete_customer_price_rule in DB.',
      );
      expect(
        _definesFn(sql, 'pricing', 'save_remembered_price_from_order'),
        isTrue,
        reason: 'TH-04 keeps save_remembered_price_from_order in DB.',
      );
      expect(
        sql.contains(
          'create table if not exists pricing.remembered_price_requests',
        ),
        isTrue,
        reason: 'remembered_price_requests table must be preserved in DB.',
      );
    });

    test('app RPC list matches repositories', () {
      final repoRoot = _findRepoRoot();
      final dataDir = Directory(
        '${repoRoot.path}/apps/erp/lib/features/pricing/data',
      );
      final dartFiles = dataDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final rpcCalls = <String>{};
      final pattern = RegExp(r"'pricing',\s*'([a-z_]+)'", multiLine: true);
      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        for (final match in pattern.allMatches(content)) {
          rpcCalls.add(match.group(1)!);
        }
      }

      const expectedNames = {
        'search_customer_price_rules',
        'get_customer_price_rule_detail',
        'get_customer_price_rule_history',
        'create_customer_price_rule',
        'update_customer_price_rule',
        'disable_customer_price_rule',
        'precheck_customer_price_rule_reenable',
        'reenable_customer_price_rule',
        'resolve_applicable_customer_price_rule',
        'preview_sales_working_state_pricing',
        'evaluate_sales_manual_price',
      };

      expect(rpcCalls, equals(expectedNames));
    });

    test('keeps source_type and activity_type labels for old import data', () {
      final repoRoot = _findRepoRoot();
      final migration014 = File(
        '${repoRoot.path}/supabase/migrations/'
        '20260725014_pricing_customer_price_rule_lifecycle_eligibility.sql',
      );

      final sql = _allMigrationsSql();
      expect(
        sql.contains(
          "check (source_type in ('manual', 'excel_import', 'sales_order', 'migration'))",
        ),
        isTrue,
        reason: 'source_type check constraint must allow excel_import',
      );

      expect(migration014.existsSync(), isTrue);
      final sql014 = migration014.readAsStringSync();
      expect(
        sql014.contains("'import_created', 'import_updated'"),
        isTrue,
        reason: '014 migration must define activity_type with import labels',
      );
    });
  });

  group('removed', () {
    test('removes import RPCs and helpers', () {
      final sql = _allMigrationsSql();
      const removedPricingFunctions = [
        'create_customer_price_rule_import',
        'get_customer_price_rule_import',
        'confirm_customer_price_rule_import',
        'cancel_customer_price_rule_import',
        '_import_batch_result',
        '_import_row_preview',
        '_evaluate_customer_price_rule_import_row',
        '_match_customer_price_rule_import_overlap',
      ];

      for (final fn in removedPricingFunctions) {
        expect(
          _definesFn(sql, 'pricing', fn),
          isFalse,
          reason: 'Expected pricing.$fn to be removed.',
        );
      }

      expect(
        _definesFn(sql, 'catalog', '_resolve_product_unit_for_pricing_import'),
        isFalse,
        reason:
            'Expected catalog._resolve_product_unit_for_pricing_import to be removed.',
      );
    });

    test('removes create/update context RPCs', () {
      final sql = _allMigrationsSql();
      expect(
        _definesFn(sql, 'pricing', 'get_customer_price_rule_create_context'),
        isFalse,
        reason: 'get_customer_price_rule_create_context must be removed.',
      );
      expect(
        _definesFn(sql, 'pricing', 'get_customer_price_rule_update_context'),
        isFalse,
        reason: 'get_customer_price_rule_update_context must be removed.',
      );
    });

    test('removes import tables', () {
      final sql = _allMigrationsSql();
      expect(
        sql.contains('pricing.customer_price_rule_imports'),
        isFalse,
        reason: 'Table pricing.customer_price_rule_imports must be removed.',
      );
      expect(
        sql.contains('pricing.customer_price_rule_import_rows'),
        isFalse,
        reason: 'Table pricing.customer_price_rule_import_rows must be removed.',
      );
    });

    test('trace columns have no FK to import tables', () {
      final sql = _allMigrationsSql();
      expect(
        sql.contains('references pricing.customer_price_rule_import'),
        isFalse,
        reason: 'Trace columns must have no FK to import tables.',
      );
    });

    test('keeps 4 import trace columns', () {
      final sql = _allMigrationsSql();
      expect(
        RegExp(
          r'add column if not exists source_import_id uuid[,;]',
        ).hasMatch(sql),
        isTrue,
        reason:
            'customer_price_rules must have source_import_id uuid without FK',
      );
      expect(
        RegExp(
          r'add column if not exists source_import_row_id uuid[,;]',
        ).hasMatch(sql),
        isTrue,
        reason:
            'customer_price_rules must have source_import_row_id uuid without FK',
      );
      expect(
        RegExp(r'add column if not exists import_id uuid[,;]').hasMatch(sql),
        isTrue,
        reason:
            'customer_price_rule_activities must have import_id uuid without FK',
      );
      expect(
        RegExp(
          r'add column if not exists import_row_id uuid[,;]',
        ).hasMatch(sql),
        isTrue,
        reason:
            'customer_price_rule_activities must have import_row_id uuid without FK',
      );
    });

    test('REGISTRY has no removed functions', () {
      final repoRoot = _findRepoRoot();
      final registryFile = File(
        '${repoRoot.path}/supabase/migrations/REGISTRY.yaml',
      );
      expect(registryFile.existsSync(), isTrue);
      final registry = registryFile.readAsStringSync();

      const removedFunctions = [
        'create_customer_price_rule_import',
        'get_customer_price_rule_import',
        'confirm_customer_price_rule_import',
        'cancel_customer_price_rule_import',
        '_import_batch_result',
        '_import_row_preview',
        '_evaluate_customer_price_rule_import_row',
        '_match_customer_price_rule_import_overlap',
        '_resolve_product_unit_for_pricing_import',
        'get_customer_price_rule_create_context',
        'get_customer_price_rule_update_context',
      ];

      for (final fn in removedFunctions) {
        expect(
          registry.contains(fn),
          isFalse,
          reason: 'REGISTRY.yaml should not contain $fn',
        );
      }

      const removedFiles = [
        '20260725003_catalog_pricing_import_product_unit_resolver.sql',
        '20260725013_pricing_customer_price_rule_import_overlap_policy.sql',
        '20260725016_pricing_customer_price_rule_import_explicit_unit.sql',
        '20260725017_pricing_customer_price_rule_import_auto_match_upsert.sql',
        '20260725018_pricing_customer_price_rule_import_price_parse.sql',
      ];

      for (final file in removedFiles) {
        expect(
          registry.contains(file),
          isFalse,
          reason: 'REGISTRY.yaml should not contain $file',
        );
      }
    });
  });
}

Directory _findRepoRoot() {
  var current = Directory.current.absolute;
  while (!Directory('${current.path}/supabase/migrations').existsSync()) {
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not locate Mosaic Retail workspace root');
    }
    current = parent;
  }
  return current;
}

String _allMigrationsSql() {
  final repoRoot = _findRepoRoot();
  final dir = Directory('${repoRoot.path}/supabase/migrations');
  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.sql') && !f.path.contains('_drafts'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return files.map((f) => f.readAsStringSync()).join('\n');
}

bool _definesFn(String sql, String schema, String name) {
  return RegExp(
    r'create\s+(or\s+replace\s+)?function\s+' +
        schema +
        r'\.' +
        name +
        r'\s*\(',
    caseSensitive: false,
  ).hasMatch(sql);
}

