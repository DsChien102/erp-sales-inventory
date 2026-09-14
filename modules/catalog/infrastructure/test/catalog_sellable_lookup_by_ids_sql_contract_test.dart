import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('resolve_sellable_products stays fail-closed and answers every requested id', () {
    final draft = File(
      '${_findRepoRoot().path}/supabase/migrations/_drafts/'
      '016_catalog_sellable_lookup_by_ids.sql',
    );

    expect(draft.existsSync(), isTrue);
    if (!draft.existsSync()) return;

    final sql = draft.readAsStringSync();
    expect(sql, contains('-- Intent: catalog_sellable_lookup_by_ids'));
    expect(sql, contains('-- Touches: resolve_sellable_products'));

    final definition = _functionDefinition(sql, 'resolve_sellable_products');

    // Same four guards as the other sellable lookups.
    expect(definition, contains('auth.uid() is null'));
    expect(definition, contains('iam.memberships'));
    expect(definition, contains("iam.has_permission(p_tenant_id, 'catalog.product.view')"));
    expect(definition, contains('iam.membership_store_scopes'));
    expect(definition, contains("store.status = 'active'"));

    // Every requested id gets an answer, so callers never read business meaning
    // out of a missing row.
    expect(definition, contains('unnest(coalesce(p_product_ids'));
    expect(definition, contains('left join catalog.products p'));
    expect(definition, contains("'resolution', 'not_found'"));
    expect(definition, contains("'resolution', 'not_sellable'"));
    expect(definition, contains("'resolution', 'sellable'"));
    expect(definition, contains("'product_inactive'"));
    expect(definition, contains("'product_not_ready_to_sell'"));
    expect(definition, contains("'no_active_price_band'"));

    // Unsellable rows must not be filtered away like search does.
    expect(definition, isNot(contains('and p.is_ready_to_sell = true')));
    expect(definition, contains('p.tenant_id = p_tenant_id'));

    expect(sql, contains('revoke all on function catalog.resolve_sellable_products(uuid, uuid, uuid[])'));
    expect(sql, contains('grant execute on function catalog.resolve_sellable_products(uuid, uuid, uuid[])'));
  });
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
