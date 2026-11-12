import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Directory _findRepoRoot() {
  var dir = Directory.current.absolute;
  while (true) {
    final candidate = File(
      '${dir.path}/supabase/migrations/20261110001_inventory_core.sql',
    );
    if (candidate.existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError(
        'Cannot find repo root from ${Directory.current.path}',
      );
    }
    dir = parent;
  }
}

void main() {
  late String rebateSql;
  late String coreSql;
  late String programSql;

  setUpAll(() {
    final root = _findRepoRoot();
    final rebateFile = File(
      '${root.path}/supabase/migrations/20261117001_inventory_supplier_rebates.sql',
    );
    rebateSql = rebateFile.existsSync() ? rebateFile.readAsStringSync() : '';
    coreSql = File(
      '${root.path}/supabase/migrations/20261110001_inventory_core.sql',
    ).readAsStringSync();
    programSql = File(
      '${root.path}/supabase/migrations/20261113001_inventory_supplier_programs.sql',
    ).readAsStringSync();
  });

  String fnSection(String sql, String fnName) {
    final marker = 'create or replace function inventory.$fnName(';
    final start = sql.indexOf(marker);
    expect(start, greaterThanOrEqualTo(0), reason: 'Missing $marker');
    final nextFn = sql.indexOf(
      'create or replace function inventory.',
      start + marker.length,
    );
    return nextFn > start ? sql.substring(start, nextFn) : sql.substring(start);
  }

  test(
    'rebate_tables_rls_revoked: both rebate tables enable RLS and revoke access',
    () {
      for (final table in [
        'inventory.supplier_rebates',
        'inventory.supplier_rebate_allocations',
      ]) {
        expect(
          rebateSql,
          contains('alter table $table enable row level security;'),
          reason: 'Missing RLS on $table',
        );
        expect(
          rebateSql,
          contains('revoke all on $table from public, anon, authenticated;'),
          reason: 'Missing revoke all on $table',
        );
      }
    },
  );

  test(
    'rebate_tables_append_only: both rebate tables forbid UPDATE and DELETE via trigger',
    () {
      for (final table in [
        'inventory.supplier_rebates',
        'inventory.supplier_rebate_allocations',
      ]) {
        expect(rebateSql, contains('on $table'));
      }
      expect(rebateSql, contains('before update or delete'));
      expect(rebateSql, contains('inventory._forbid_ledger_mutation()'));
    },
  );

  test(
    'value_adjustment_not_granted: internal helpers revoke all and are not granted',
    () {
      final helpers = <String, String>{
        '_post_value_adjustment':
            'uuid, uuid, text, bigint, date, uuid, uuid, uuid',
        '_rebate_allocation': 'uuid, uuid, bigint',
      };
      for (final entry in helpers.entries) {
        final name = entry.key;
        final sig = entry.value;
        expect(
          rebateSql,
          contains('create or replace function inventory.$name('),
        );
        expect(
          rebateSql,
          contains(
            'revoke all on function inventory.$name($sig) from public, anon, authenticated;',
          ),
        );
        expect(
          rebateSql,
          isNot(
            contains(
              'grant execute on function inventory.$name($sig) to authenticated;',
            ),
          ),
        );
      }
    },
  );

  test(
    'rebate_rpcs_owner_only: preview and record RPCs are security definer, granted, assert actor and require owner',
    () {
      final rpcs = <String, String>{
        'preview_supplier_rebate': 'uuid, uuid, bigint',
        'record_supplier_rebate': 'uuid, text, uuid, jsonb',
      };
      for (final entry in rpcs.entries) {
        final body = fnSection(rebateSql, entry.key);
        expect(body, contains('security definer'));
        expect(
          body,
          contains("inventory._assert_actor(p_tenant_id, 'inventory.read')"),
        );
        expect(body, contains("'is_owner'"));
        expect(body, contains("'PERMISSION_DENIED'"));
        expect(
          rebateSql,
          contains(
            'grant execute on function inventory.${entry.key}(${entry.value}) to authenticated;',
          ),
        );
      }
    },
  );

  test(
    'record_idempotent: record_supplier_rebate uses supplier_rebate.record idempotency scope',
    () {
      final body = fnSection(rebateSql, 'record_supplier_rebate');
      expect(body, contains('inventory._begin_idempotency('));
      expect(body, contains("'supplier_rebate.record'"));
      expect(body, contains('inventory._complete_idempotency('));
    },
  );

  test(
    'record_locks_program_then_products: program FOR UPDATE < advisory lock < _rebate_allocation',
    () {
      final body = fnSection(rebateSql, 'record_supplier_rebate');
      final forUpdatePos = body.indexOf('for update');
      final lockPos = body.indexOf('pg_advisory_xact_lock');
      final allocPos = body.indexOf('inventory._rebate_allocation(');
      expect(forUpdatePos, greaterThanOrEqualTo(0));
      expect(lockPos, greaterThan(forUpdatePos));
      expect(allocPos, greaterThan(lockPos));
    },
  );

  test(
    'record_does_not_call_value_line: rebate migration never calls _value_line or _post_movements',
    () {
      expect(rebateSql, isNotEmpty);
      expect(rebateSql, isNot(contains('_value_line(')));
      expect(rebateSql, isNot(contains('_post_movements(')));
    },
  );

  test(
    'hub_counts_programs_reached: get_warehouse_hub_summary counts reached supplier programs',
    () {
      final body = fnSection(coreSql, 'get_warehouse_hub_summary');
      expect(body, contains("'programs_reached'"));
      expect(body, contains('supplier_programs'));
    },
  );

  test(
    'new_error_codes_present: all 3 rebate error codes exist in rebate migration',
    () {
      for (final code in [
        'PROGRAM_NOT_REACHED',
        'REBATE_AMOUNT_INVALID',
        'REBATE_REASON_REQUIRED',
      ]) {
        expect(rebateSql, contains("'$code'"));
      }
    },
  );

  test(
    'rebate_fk_added: value_movements.supplier_rebate_id FK is added',
    () {
      expect(rebateSql, contains('value_movements_supplier_rebate_fk'));
      expect(
        rebateSql,
        contains('foreign key (supplier_rebate_id) references inventory.supplier_rebates (id)'),
      );
    },
  );

  test(
    'get_supplier_program_returns_owner_and_rebate: 20261113001 adds viewer_is_owner and rebate',
    () {
      final body = fnSection(programSql, 'get_supplier_program');
      expect(body, contains("'viewer_is_owner'"));
      expect(body, contains("'rebate'"));
    },
  );

  test(
    'read_rpcs_granted: get_projected_cost and compare_suppliers are security definer, granted, and assert actor',
    () {
      final rpcs = <String, String>{
        'get_projected_cost': 'uuid, uuid, uuid, numeric, numeric',
        'compare_suppliers': 'uuid, uuid',
      };
      for (final entry in rpcs.entries) {
        final body = fnSection(rebateSql, entry.key);
        expect(body, contains('security definer'));
        expect(
          body,
          contains("inventory._assert_actor(p_tenant_id, 'inventory.read')"),
        );
        expect(
          rebateSql,
          contains(
            'grant execute on function inventory.${entry.key}(${entry.value}) to authenticated;',
          ),
        );
      }
    },
  );

  test(
    'read_rpcs_mask_money: get_projected_cost and compare_suppliers include financial_masked',
    () {
      for (final fnName in ['get_projected_cost', 'compare_suppliers']) {
        final body = fnSection(rebateSql, fnName);
        expect(body, contains("'financial_masked'"));
      }
    },
  );

  test(
    'projection_writes_nothing: get_projected_cost body contains no insert, update, or _post_value_adjustment(',
    () {
      final body = fnSection(rebateSql, 'get_projected_cost').toLowerCase();
      expect(body, isNot(contains('insert')));
      expect(body, isNot(contains('update')));
      expect(body, isNot(contains('_post_value_adjustment(')));
    },
  );
}

