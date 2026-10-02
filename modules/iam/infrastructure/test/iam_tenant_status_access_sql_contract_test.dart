import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — block suspended/closed tenants server-side
/// (docs/superpowers/specs/iam-schema-refactor/16-tenant-status-access.md).
void main() {
  test('has_permission raises for suspended/closed tenant, not provisioning', () {
    final b = _lastFunctionBlock(
      _readMigration('20260811024_iam_patch_owner_role_canonicalization.sql'),
      'iam.has_permission',
    );
    expect(b, contains('join iam.tenants t on t.id = m.tenant_id'));
    expect(b, contains("if v_tenant_status = 'suspended' then\n    raise exception 'TENANT_SUSPENDED';"));
    expect(b, contains("if v_tenant_status = 'closed' then\n    raise exception 'TENANT_CLOSED';"));
    expect(b, isNot(contains("'provisioning'")));
    // Tenant check happens after membership check, before owner shortcut.
    expect(b.indexOf("'TENANT_SUSPENDED'"), greaterThan(b.indexOf("coalesce(v_status, 'active') <> 'active'")));
    expect(b.indexOf("'TENANT_SUSPENDED'"), lessThan(b.indexOf('if coalesce(v_is_owner, false) then')));
  });

  test('can_access_store excludes suspended/closed tenants', () {
    final b = _lastFunctionBlock(
      _readMigration('20260830001_iam_active_store_context_group_a.sql'),
      'iam.can_access_store',
    );
    expect(b, contains('join iam.tenants t'));
    expect(b, contains("t.status not in ('suspended', 'closed')"));
  });

  test('get_session_context raises tenant status codes', () {
    final b = _lastFunctionBlock(
      _readMigration('20260914001_iam_get_session_context_multi_tenant.sql'),
      'iam.get_session_context',
    );
    expect(b, contains('"code":"TENANT_SUSPENDED"'));
    expect(b, contains('"code":"TENANT_CLOSED"'));
    expect(b.indexOf('"code":"TENANT_SUSPENDED"'), lessThan(b.indexOf('from iam.stores store')));
  });

  test('basic stock RPCs assert manage_stock permission', () {
    final sql = _readMigration('20260712003_catalog_rename_basic_stock_quantity_base.sql');
    for (final fn in ['catalog.adjust_basic_stock', 'catalog.set_basic_stock_quantity_base']) {
      expect(
        _lastFunctionBlock(sql, fn),
        contains("perform catalog._assert_product_permission(p_tenant_id, 'catalog.product.manage_stock');"),
        reason: fn,
      );
    }
  });
}

String _readMigration(String fileName) {
  final root = _findRepoRoot();
  return File('${root.path}/supabase/migrations/$fileName').readAsStringSync();
}

/// Last `create or replace function <qualifiedName>(` … `$$;` in [sql].
String _lastFunctionBlock(String sql, String qualifiedName) {
  final start = sql.lastIndexOf('create or replace function $qualifiedName(');
  if (start < 0) {
    throw StateError('$qualifiedName not found');
  }
  final bodyStart = sql.indexOf(r'as $$', start);
  final end = sql.indexOf(r'$$;', bodyStart + 5);
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
