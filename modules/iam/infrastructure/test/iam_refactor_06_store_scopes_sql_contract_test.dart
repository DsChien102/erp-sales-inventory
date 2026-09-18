import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — IAM refactor bảng 6: remove membership_store_scopes
/// (docs/superpowers/specs/iam-schema-refactor/06-membership-store-scopes.md).
void main() {
  group('store scope DDL removed; can_access_store added', () {
    final activeStore =
        _readMigration('20260830001_iam_active_store_context_group_a.sql');

    test('no scope table, index, policy or grant is created', () {
      expect(
        activeStore,
        isNot(contains('create table if not exists iam.membership_store_scopes')),
      );
      expect(activeStore, isNot(contains('membership_store_scopes_one_default')));
      expect(
        activeStore,
        isNot(contains('create policy membership_store_scopes_self_read')),
      );
      expect(activeStore, contains('grant select on iam.stores to authenticated;'));
    });

    test('can_access_store checks active store and active member, not exposed',
        () {
      final body = _lastFunctionBlock(activeStore, 'iam.can_access_store');
      expect(body, contains("s.status = 'active'"));
      expect(body, contains('m.is_active'));
      expect(
        activeStore.indexOf('create or replace function iam.can_access_store('),
        greaterThan(
          activeStore.indexOf('create table if not exists iam.stores ('),
        ),
      );
      expect(
        activeStore,
        contains(
          'revoke all on function iam.can_access_store(uuid, uuid, uuid) from public, anon, authenticated;',
        ),
      );
    });

    test('legacy scope helper and backfill loop removed', () {
      final helpers = _readMigration(
        '20260916001_iam_ensure_default_store_scope_helpers.sql',
      );
      expect(helpers, isNot(contains('_ensure_membership_default_store_scope')));
      final backfill =
          _readMigration('20260916003_iam_backfill_default_store_scopes.sql');
      expect(backfill, isNot(contains('membership_store_scopes')));
      expect(backfill, isNot(contains('_ensure_membership_default_store_scope')));
    });
  });

  group('iam functions no longer touch store scopes', () {
    const owners = {
      'iam.get_session_context':
          '20260914001_iam_get_session_context_multi_tenant.sql',
      'iam.bootstrap_owner':
          '20260914001_iam_get_session_context_multi_tenant.sql',
      'iam.create_tenant_onboarding':
          '20260916004_iam_patch_onboarding_default_store_scope.sql',
      'iam.create_tenant_invitation':
          '20260916005_iam_patch_invitation_membership_store_scope.sql',
      'iam.accept_invitation':
          '20260916006_iam_patch_accept_invitation_default_store_scope.sql',
      'iam.activate_tenant':
          '20260916007_iam_patch_activate_tenant_default_store_scope.sql',
    };

    test('no scope table or legacy helper', () {
      for (final entry in owners.entries) {
        final body = _lastFunctionBlock(_readMigration(entry.value), entry.key);
        expect(
          body,
          isNot(contains('membership_store_scopes')),
          reason: entry.key,
        );
        expect(
          body,
          isNot(contains('_ensure_membership_default_store_scope')),
          reason: entry.key,
        );
      }
    });

    test('session context resolves active store through helper', () {
      expect(
        _lastFunctionBlock(
          _readMigration(owners['iam.get_session_context']!),
          'iam.get_session_context',
        ),
        contains('iam.can_access_store(v_tenant_id, v_active_store_id, v_user_id)'),
      );
    });
  });

  group('sales store access', () {
    const f06 = '20260830006_sales_shared_rpc_helpers.sql';
    const f10 = '20260830010_sales_inquiry_receipt_rpcs.sql';
    const f11 = '20260830011_sales_adjustment_cancellation_rpcs.sql';
    const f12 = '20260830012_sales_return_exchange_session_rpcs.sql';

    test(
      '20 functions use can_access_store',
      () => _expectUsesStoreAccess(const {
            'sales._assert_sales_actor': f06,
            'sales.get_sales_order': f10,
            'sales.get_sales_order_payment_summary': f10,
            'sales.get_order_integration_status': f10,
            'sales.list_sales_orders': f10,
            'sales.search_sales_orders': f10,
            'sales.get_sales_order_detail': f10,
            'sales.get_sales_order_settlement': f10,
            'sales.get_sales_order_payment_transactions': f10,
            'sales.get_sales_order_timeline': f10,
            'sales.get_sales_order_return_summary': f10,
            'sales.get_sales_receipt': f10,
            'sales.record_sales_receipt_activity': f10,
            'sales.get_available_post_sale_actions': f11,
            'sales.precheck_sales_order_cancellation': f11,
            'sales.get_sales_order_cancellation': f11,
            'sales.precheck_return_exchange': f12,
            'sales.get_returnable_order_lines': f12,
            'sales._get_return_exchange_context': f12,
            'sales.get_return_exchange_detail': f12,
          }),
    );

    test('assert actor keeps DATA_SCOPE_DENIED', () {
      final body =
          _lastFunctionBlock(_readMigration(f06), 'sales._assert_sales_actor');
      expect(
        body,
        contains('if not iam.can_access_store(p_tenant_id, p_store_id, p_actor_id) then'),
      );
      expect(body, contains("'DATA_SCOPE_DENIED'"));
    });

    test('list/search keep per-order store filter', () {
      final sql = _readMigration(f10);
      expect(
        _lastFunctionBlock(sql, 'sales.list_sales_orders'),
        contains(
          'and iam.can_access_store(list_sales_orders.tenant_id, o.store_id, list_sales_orders.actor_id)',
        ),
      );
      expect(
        _lastFunctionBlock(sql, 'sales.search_sales_orders'),
        contains(
          'and iam.can_access_store(search_sales_orders.tenant_id, o.store_id, search_sales_orders.actor_id)',
        ),
      );
    });
  });

  group('catalog/pricing store access', () {
    test(
      '6 functions use can_access_store',
      () => _expectUsesStoreAccess(const {
            'catalog.search_sellable_products':
                '20260830002_catalog_sales_sellable_lookup_group_a.sql',
            'catalog.resolve_sellable_barcode':
                '20260830002_catalog_sales_sellable_lookup_group_a.sql',
            'catalog.list_sellable_product_units':
                '20260830002_catalog_sales_sellable_lookup_group_a.sql',
            'catalog.resolve_sellable_products':
                '20260831001_catalog_sellable_lookup_by_ids.sql',
            'pricing.preview_sales_working_state_pricing':
                '20260830003_pricing_sales_working_state_preview_group_a.sql',
            'pricing.evaluate_sales_manual_price':
                '20260830003_pricing_sales_working_state_preview_group_a.sql',
          }),
    );
  });
}

void _expectUsesStoreAccess(Map<String, String> ownerByFunction) {
  for (final entry in ownerByFunction.entries) {
    final body = _lastFunctionBlock(_readMigration(entry.value), entry.key);
    expect(body, isNot(contains('membership_store_scopes')), reason: entry.key);
    expect(body, contains('iam.can_access_store('), reason: entry.key);
  }
}

String _readMigration(String fileName) {
  final root = _findRepoRoot();
  return File('${root.path}/supabase/migrations/$fileName').readAsStringSync();
}

String _lastFunctionBlock(String sql, String qualifiedName) {
  final start = sql.lastIndexOf('create or replace function $qualifiedName(');
  if (start < 0) {
    throw StateError('$qualifiedName not found');
  }
  final end = sql.indexOf(r'$$;', start);
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
