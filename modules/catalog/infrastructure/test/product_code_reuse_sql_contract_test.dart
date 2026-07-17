import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('SKU and barcode uniqueness excludes soft-deleted products', () {
    final drafts = Directory(
      '${_findRepoRoot().path}/supabase/migrations/_drafts',
    );
    final schema = File(
      '${drafts.path}/catalog_product_code_reuse_after_soft_delete_schema.sql',
    ).readAsStringSync();
    final rpcs = File(
      '${drafts.path}/catalog_product_code_reuse_after_soft_delete_rpcs.sql',
    ).readAsStringSync();

    for (final legacyName in <String>[
      'uq_products_tenant_sku',
      'uq_products_tenant_barcode',
    ]) {
      expect(
        schema,
        contains('drop constraint if exists $legacyName'),
        reason: 'Legacy table constraint $legacyName must be removed',
      );
      expect(
        schema,
        contains('drop index if exists catalog.$legacyName'),
        reason: 'Legacy standalone index $legacyName must be removed',
      );
    }
    expect(schema, contains('uq_products_tenant_non_deleted_sku'));
    expect(schema, contains('uq_products_tenant_non_deleted_barcode'));
    expect(
      _nonDeletedPredicate.allMatches(schema),
      hasLength(2),
      reason: 'Both partial unique indexes must exclude soft-deleted rows',
    );

    _expectPredicateCount(rpcs, 'check_duplicate_product_code', 2);
    _expectPredicateCount(rpcs, 'create_product', 4);
    _expectPredicateCount(rpcs, 'update_product_profile', 4);
  });
}

final _nonDeletedPredicate = RegExp(
  r"business_status\s*<>\s*'soft_deleted'::catalog\.product_business_status",
);

void _expectPredicateCount(String sql, String functionName, int count) {
  final definition = _functionDefinition(sql, functionName);
  expect(
    _nonDeletedPredicate.allMatches(definition),
    hasLength(count),
    reason: '$functionName must ignore soft-deleted SKU/barcode owners',
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
