import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('catalog', () {
    test('products_has_tracking_columns', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20260709001_catalog_guided_create.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      expect(sql, contains("tracking_mode text not null default 'none'"));
      expect(sql, contains('expiry_required boolean not null default false'));
      expect(sql, contains('chk_products_tracking_mode'));
      expect(sql, contains('chk_products_expiry_requires_lot'));
    });

    test('guided_create_accepts_tracking', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20260722001_catalog_pending_automatic_price_bands.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      final guided = _functionDefinition(sql, 'create_guided_product');
      expect(guided, contains("p_tracking_mode text default 'none'"));
      expect(guided, contains('p_expiry_required boolean default false'));
    });

    test('profile_update_keeps_tracking_when_null', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20260717005_catalog_product_code_reuse_after_soft_delete_rpcs.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      final update = _functionDefinition(sql, 'update_product_profile');
      expect(update, contains('p_tracking_mode text default null'));
      expect(update, contains('p_expiry_required boolean default null'));
      expect(update, contains('coalesce(p_tracking_mode'));
    });

    test('pcc_returns_tracking_and_movements_flag', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20260725019_catalog_search_pcc_price_after_vat.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      final pcc = _functionDefinition(sql, 'get_product_control_center');
      expect(pcc, contains("'tracking_mode'"));
      expect(pcc, contains("'expiry_required'"));
      expect(pcc, contains("'has_inventory_movements'"));
    });
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
