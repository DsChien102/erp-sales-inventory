import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String sql;

  setUpAll(() {
    final repoRoot = _findRepoRoot();
    final file = File(
      '${repoRoot.path}/supabase/migrations/20261113001_inventory_supplier_programs.sql',
    );
    expect(file.existsSync(), isTrue, reason: 'Migration file must exist');
    sql = file.readAsStringSync();
  });

  group('inventory_supplier_programs SQL contract', () {
    test('program_tables_rls_revoked', () {
      for (final t in [
        'supplier_programs',
        'supplier_program_products',
        'supplier_program_tiers',
        'supplier_program_receipts',
      ]) {
        expect(
          sql,
          contains('alter table inventory.$t enable row level security'),
        );
        expect(
          sql,
          contains(
            'revoke all on inventory.$t from public, anon, authenticated',
          ),
        );
      }
    });

    test('program_rpcs_granted', () {
      for (final f in [
        'list_supplier_programs(uuid)',
        'get_supplier_program(uuid, uuid)',
        'get_supplier_program_form_options(uuid)',
        'create_supplier_program(uuid, text, jsonb)',
        'update_supplier_program(uuid, text, uuid, int, jsonb)',
        'end_supplier_program(uuid, text, uuid, int)',
        'get_receipt_program_hints(uuid, uuid, jsonb)',
      ]) {
        expect(
          sql,
          contains('grant execute on function inventory.$f to authenticated'),
        );
      }
      for (final h in [
        '_program_is_locked(uuid)',
        '_ensure_walk_in_supplier(uuid)',
      ]) {
        expect(
          sql,
          contains(
            'revoke all on function inventory.$h from public, anon, authenticated',
          ),
        );
      }
      expect(
        RegExp('security definer').allMatches(sql).length,
        greaterThanOrEqualTo(9),
      );
      expect(
        RegExp(
          r"_assert_actor\(p_tenant_id, 'inventory\.read'\)",
        ).allMatches(sql).length,
        7,
      );
      expect(sql, isNot(contains("'inventory.read', true")));
    });

    test('write_rpcs_idempotent', () {
      expect(
        RegExp(r'_begin_idempotency\(').allMatches(sql).length,
        3,
      );
      expect(
        RegExp(r'_complete_idempotency\(').allMatches(sql).length,
        3,
      );
      expect(sql, contains("'supplier_program.create'"));
      expect(sql, contains("'supplier_program.update'"));
      expect(sql, contains("'supplier_program.end'"));
    });

    test('one_effective_per_supplier_index', () {
      expect(sql, contains('supplier_programs_one_effective_per_supplier'));
      expect(sql, contains("where status in ('ACTIVE','REACHED')"));
    });

    test('new_error_codes_present', () {
      for (final code in [
        'PROGRAM_SUPPLIER_INVALID',
        'PROGRAM_UOM_MISMATCH',
        'PROGRAM_OVERLAP',
        'PROGRAM_LOCKED',
      ]) {
        expect(sql, contains("'$code'"));
      }
    });

    test('overlap_catches_unique_violation', () {
      expect(sql, contains('when unique_violation then'));
      expect(sql, contains("'PROGRAM_OVERLAP'"));
    });
  });
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

