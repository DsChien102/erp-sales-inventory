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

  group('schema', () {
    test('core_tables_exist', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20261110001_inventory_core.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      final expectedTables = [
        'ledger_counters',
        'lots',
        'stock_movements',
        'stock_balances',
        'value_movements',
        'product_costs',
        'cost_policies',
        'cost_periods',
        'cost_versions',
      ];
      for (final table in expectedTables) {
        expect(sql, contains('create table inventory.$table'));
      }
      expect(
        sql,
        isNot(contains('create table inventory.tenant_inventory_settings')),
      );
      expect(
        sql,
        isNot(contains('create table inventory.approval_cases')),
      );
    });

    test('rls_and_revoke_for_every_table', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20261110001_inventory_core.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      final expectedTables = [
        'ledger_counters',
        'lots',
        'stock_movements',
        'stock_balances',
        'value_movements',
        'product_costs',
        'cost_policies',
        'cost_periods',
        'cost_versions',
      ];
      for (final table in expectedTables) {
        expect(
          sql,
          contains('alter table inventory.$table enable row level security;'),
        );
        expect(
          sql,
          contains(
            'revoke all on inventory.$table from public, anon, authenticated;',
          ),
        );
      }
    });

    test('no_state_columns', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20261110001_inventory_core.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      expect(sql, isNot(contains('stock_state')));
      expect(sql, isNot(contains('from_state')));
      expect(sql, isNot(contains('to_state')));
      expect(sql, isNot(contains('valuation_state')));
    });

    test('movement_kind_and_reason_values', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20261110001_inventory_core.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      final expectedKinds = [
        'OPENING',
        'RECEIPT',
        'SALE',
        'SALE_REVERSAL',
        'RETURN_IN',
        'COUNT_GAIN',
        'COUNT_LOSS',
        'WRITE_OFF',
      ];
      for (final kind in expectedKinds) {
        expect(sql, contains("'$kind'"));
      }
      final expectedReasons = [
        'DAMAGED',
        'EXPIRED',
        'LOSS',
        'COUNT',
      ];
      for (final reason in expectedReasons) {
        expect(sql, contains("'$reason'"));
      }
    });

    test('balance_unique_key_and_non_negative', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20261110001_inventory_core.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      expect(
        sql,
        contains(
          'unique (tenant_id, warehouse_id, product_id, lot_key)',
        ),
      );
      expect(sql, contains('physical_quantity >= 0'));
    });

    test('value_movements_shape', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20261110001_inventory_core.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      final valueKinds = [
        'OPENING',
        'RECEIPT',
        'SALE',
        'SALE_REVERSAL',
        'RETURN_IN',
        'COUNT_GAIN',
        'COUNT_LOSS',
        'WRITE_OFF',
        'COGS_TRUE_UP',
        'LOSS_TRUE_UP',
        'REVALUE_ROUNDING',
        'SUPPLIER_REBATE',
      ];
      for (final kind in valueKinds) {
        expect(sql, contains("'$kind'"));
      }
      expect(sql, contains('amount_vnd bigint not null'));
      expect(sql, contains('unit_cost numeric(18,4)'));
      expect(
        sql,
        contains('movement_id is null and cost_run_id is not null'),
      );
      expect(
        sql,
        contains('movement_id is null and supplier_rebate_id is not null'),
      );
    });

    test('product_costs_shape', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20261110001_inventory_core.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      expect(sql, contains('primary key (tenant_id, product_id)'));
      expect(sql, contains('ledger_value_vnd bigint'));
      expect(sql, contains('moving_avg_cost numeric(18,4)'));
      expect(sql, contains('quantity_on_hand >= 0'));
    });

    test('cost_tables_shape', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20261110001_inventory_core.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      expect(sql, contains("method in ('MOVING', 'PERIODIC')"));
      expect(sql, contains("status in ('OPEN', 'CLOSED')"));
      expect(sql, contains('unique (tenant_id, period_month)'));
    });

    test('ledger_append_only_trigger', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20261110001_inventory_core.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      expect(sql, contains('before update or delete on inventory.stock_movements'));
      expect(sql, contains('before update or delete on inventory.value_movements'));
      expect(sql, contains('before update or delete on inventory.cost_versions'));
      expect(sql, contains('_forbid_ledger_mutation'));
    });

    test('tracking_lock_trigger', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20261110001_inventory_core.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      expect(
        sql,
        contains(
          'before update of tracking_mode, expiry_required on catalog.products',
        ),
      );
      expect(sql, contains('_lock_tracking_after_movement'));
    });
  });

  group('helpers', () {
    test('helpers_not_granted', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20261110001_inventory_core.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      final helperNames = [
        '_assert_actor',
        '_begin_idempotency',
        '_complete_idempotency',
        '_available_quantity',
        '_cost_method',
        '_ensure_open_period',
      ];
      for (final name in helperNames) {
        expect(sql, contains('on function inventory.$name('));
        expect(
          sql,
          isNot(contains('grant execute on function inventory.$name(')),
        );
      }
    });

    test('assert_actor_checks_in_order', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20261110001_inventory_core.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      final body = _functionDefinition(
        sql,
        '_assert_actor',
        schema: 'inventory',
      );
      final permIdx = body.indexOf('has_permission');
      final ownerIdx = body.indexOf('is_owner');
      final assignIdx = body.indexOf('store_warehouse_assignments');
      expect(permIdx, isNonNegative);
      expect(ownerIdx, isNonNegative);
      expect(assignIdx, isNonNegative);
      expect(permIdx < ownerIdx, isTrue);
      expect(ownerIdx < assignIdx, isTrue);
    });

    test('assert_actor_no_activation', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20261110001_inventory_core.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      final body = _functionDefinition(
        sql,
        '_assert_actor',
        schema: 'inventory',
      );
      expect(body.toLowerCase(), isNot(contains('activation')));
      expect(body, isNot(contains('INVENTORY_NOT_ACTIVATED')));
    });

    test('idempotency_conflict_code', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20261110001_inventory_core.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      final body = _functionDefinition(
        sql,
        '_begin_idempotency',
        schema: 'inventory',
      );
      expect(body, contains('IDEMPOTENCY_CONFLICT'));
    });

    test('cost_method_defaults_moving', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20261110001_inventory_core.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      final body = _functionDefinition(
        sql,
        '_cost_method',
        schema: 'inventory',
      );
      expect(body, contains("'MOVING'"));
    });

    test('ensure_period_raises_closed', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20261110001_inventory_core.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      final body = _functionDefinition(
        sql,
        '_ensure_open_period',
        schema: 'inventory',
      );
      expect(body, contains('PERIOD_CLOSED'));
    });
  });

  group('post_movements', () {
    test('period_check_before_lock', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20261110001_inventory_core.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      final body = _functionDefinition(
        sql,
        '_post_movements',
        schema: 'inventory',
      );
      final periodIdx = body.indexOf('_ensure_open_period');
      final lockIdx = body.indexOf('pg_advisory_xact_lock');
      expect(periodIdx, isNonNegative);
      expect(lockIdx, isNonNegative);
      expect(periodIdx < lockIdx, isTrue);
    });

    test('advisory_lock_before_balance_read', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20261110001_inventory_core.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      final body = _functionDefinition(
        sql,
        '_post_movements',
        schema: 'inventory',
      );
      final lockIdx = body.indexOf('pg_advisory_xact_lock');
      final balanceIdx = body.indexOf('stock_balances');
      expect(lockIdx, isNonNegative);
      expect(balanceIdx, isNonNegative);
      expect(lockIdx < balanceIdx, isTrue);
      expect(body, contains('for update'));
    });

    test('lot_rules_codes', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20261110001_inventory_core.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      final body = _functionDefinition(
        sql,
        '_post_movements',
        schema: 'inventory',
      );
      expect(body, contains('LOT_REQUIRED'));
      expect(body, contains('LOT_NOT_ALLOWED'));
      expect(body, contains('EXPIRY_REQUIRED'));
    });

    test('insufficient_stock_code', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20261110001_inventory_core.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      final body = _functionDefinition(
        sql,
        '_post_movements',
        schema: 'inventory',
      );
      expect(body, contains('INSUFFICIENT_STOCK'));
    });

    test('unit_cost_required_code', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20261110001_inventory_core.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      final body = _functionDefinition(
        sql,
        '_value_line',
        schema: 'inventory',
      );
      expect(body, contains('UNIT_COST_REQUIRED'));
    });

    test('value_line_called_per_line', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20261110001_inventory_core.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      final body = _functionDefinition(
        sql,
        '_post_movements',
        schema: 'inventory',
      );
      expect(body, contains('_value_line'));
    });

    test('value_line_branches', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20261110001_inventory_core.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      final body = _functionDefinition(
        sql,
        '_value_line',
        schema: 'inventory',
      );
      expect(body, contains("'MOVING'"));
      expect(body, contains("'PERIODIC'"));
      expect(body, contains('is_provisional'));
      expect(body, contains('moving_avg_cost'));
      expect(body, contains('official_unit_cost'));
    });

    test('returns_lines_and_stock_changes', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20261110001_inventory_core.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      final body = _functionDefinition(
        sql,
        '_post_movements',
        schema: 'inventory',
      );
      expect(body, contains("'lines'"));
      expect(body, contains("'stock_changes'"));
    });
  });

  group('public', () {
    test('hub_summary_granted_definer', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20261110001_inventory_core.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      final body = _functionDefinition(
        sql,
        'get_warehouse_hub_summary',
        schema: 'inventory',
      );
      expect(body, contains('security definer'));
      expect(body, contains('search_path = inventory, iam, catalog, pg_temp'));
      expect(
        sql,
        contains(
          'grant execute on function inventory.get_warehouse_hub_summary(uuid) to authenticated;',
        ),
      );
    });

    test('hub_summary_shape', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20261110001_inventory_core.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      final body = _functionDefinition(
        sql,
        'get_warehouse_hub_summary',
        schema: 'inventory',
      );
      expect(body, contains("'activated'"));
      expect(body, contains("'problems'"));
      expect(body, isNot(contains("'pending'")));
      expect(body, isNot(contains("'reconciliation'")));
    });

    test('no_approval_or_outcome_rpc', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20261110001_inventory_core.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      expect(sql, isNot(contains('_open_approval')));
      expect(sql, isNot(contains('_decide_approval')));
      expect(sql, isNot(contains('get_command_outcome')));
      expect(sql, isNot(contains('function inventory._activate')));
    });

    test('all_core_error_codes_present', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20261110001_inventory_core.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      final coreCodes = [
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
      ];
      for (final code in coreCodes) {
        expect(sql, contains("'$code'"));
      }
    });

    test('no_removed_error_codes', () {
      final repoRoot = _findRepoRoot();
      final migration = File(
        '${repoRoot.path}/supabase/migrations/20261110001_inventory_core.sql',
      );
      expect(migration.existsSync(), isTrue);
      final sql = migration.readAsStringSync();
      final removedCodes = [
        'INVENTORY_NOT_ACTIVATED',
        'APPROVAL_ALREADY_OPEN',
        'APPROVAL_ALREADY_DECIDED',
        'REASON_REQUIRED',
      ];
      for (final code in removedCodes) {
        expect(sql, isNot(contains("'$code'")));
      }
    });
  });
}

String _functionDefinition(
  String sql,
  String functionName, {
  String schema = 'catalog',
}) {
  final start = sql.indexOf(
    'create or replace function $schema.$functionName(',
  );
  if (start < 0) {
    throw StateError('Could not locate $schema.$functionName');
  }
  final end = sql.indexOf(r'$$;', start);
  if (end < 0) {
    throw StateError('Could not locate the end of $schema.$functionName');
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
