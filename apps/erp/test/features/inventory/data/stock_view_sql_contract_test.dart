import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory repoRoot;
  late File stockViewFile;
  late File coreFile;

  setUpAll(() {
    repoRoot = _findRepoRoot();
    stockViewFile = File(
      '${repoRoot.path}/supabase/migrations/20261112001_inventory_stock_view.sql',
    );
    coreFile = File(
      '${repoRoot.path}/supabase/migrations/20261110001_inventory_core.sql',
    );
  });

  group('inventory_stock_view SQL contract', () {
    test('stock_view_rpcs_granted', () {
      expect(
        stockViewFile.existsSync(),
        isTrue,
        reason: 'Migration 20261112001_inventory_stock_view.sql must exist',
      );
      final sql = stockViewFile.readAsStringSync();

      for (final sig in [
        'list_stock_overview(uuid)',
        'get_stock_detail(uuid, uuid)',
      ]) {
        expect(
          sql,
          contains('grant execute on function inventory.$sig to authenticated'),
        );
      }

      for (final fn in ['list_stock_overview', 'get_stock_detail']) {
        final body = _functionDefinition(sql, fn, schema: 'inventory');
        expect(body, contains('security definer'));
        expect(body, contains('set search_path = inventory, iam, catalog, pg_temp'));
        expect(
          body,
          contains("inventory._assert_actor(p_tenant_id, 'inventory.read')"),
        );
      }
    });

    test('detail_masks_cost_for_non_owner', () {
      expect(stockViewFile.existsSync(), isTrue);
      final sql = stockViewFile.readAsStringSync();
      final body = _functionDefinition(
        sql,
        'get_stock_detail',
        schema: 'inventory',
      );
      expect(body, contains("'financial_masked'"));
      expect(body, contains('is_owner'));
    });

    test('hub_summary_fills_problems', () {
      expect(coreFile.existsSync(), isTrue);
      final sql = coreFile.readAsStringSync();
      final body = _functionDefinition(
        sql,
        'get_warehouse_hub_summary',
        schema: 'inventory',
      );
      expect(body, contains("'near_expiry'"));
      expect(body, contains("'products'"));
      expect(body, contains('_product_stock_rows'));

      // Activated branch must build problems object, not return null
      final nonActivatedCount = RegExp(
        r"'problems'\s*,\s*null",
      ).allMatches(body).length;
      expect(
        nonActivatedCount,
        lessThanOrEqualTo(1),
        reason: 'Only unactivated branch may return problems: null',
      );
      expect(body, contains('jsonb_build_object(\n      \'out\''));
    });

    test('no_new_error_codes', () {
      expect(stockViewFile.existsSync(), isTrue);
      final sql = stockViewFile.readAsStringSync();
      final codes = RegExp(r"_raise\('([A-Z_]+)'")
          .allMatches(sql)
          .map((m) => m[1])
          .toSet();
      expect(
        codes.difference({
          'PERMISSION_DENIED',
          'CONTEXT_INVALID',
          'DATA_SCOPE_DENIED',
          'IDEMPOTENCY_CONFLICT',
          'COMMAND_IN_PROGRESS',
          'VERSION_CONFLICT',
          'INSUFFICIENT_STOCK',
          'LOT_REQUIRED',
          'LOT_NOT_ALLOWED',
          'EXPIRY_REQUIRED',
          'LOT_ATTRIBUTE_CONFLICT',
          'TRACKING_LOCKED',
          'UNIT_COST_REQUIRED',
          'PERIOD_CLOSED',
        }),
        isEmpty,
      );
    });
  });
}

String _functionDefinition(
  String sql,
  String functionName, {
  required String schema,
}) {
  final pattern = RegExp(
    'create\\s+or\\s+replace\\s+function\\s+$schema\\.$functionName\\b[\\s\\S]*?\\\$\\\$\\s*;',
    caseSensitive: false,
  );
  final match = pattern.firstMatch(sql);
  expect(
    match,
    isNotNull,
    reason: 'Function $schema.$functionName not found in migration',
  );
  return match!.group(0)!;
}

Directory _findRepoRoot() {
  var current = Directory.current.absolute;
  while (!Directory('${current.path}/supabase/migrations').existsSync()) {
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not locate workspace root');
    }
    current = parent;
  }
  return current;
}

