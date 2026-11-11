import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String receiptSql;
  late String programSql;

  setUpAll(() {
    final repoRoot = _findRepoRoot();
    final receiptFile = File(
      '${repoRoot.path}/supabase/migrations/20261114001_inventory_goods_receipts.sql',
    );
    expect(receiptFile.existsSync(), isTrue, reason: '20261114001 migration must exist');
    receiptSql = receiptFile.readAsStringSync();

    final programFile = File(
      '${repoRoot.path}/supabase/migrations/20261113001_inventory_supplier_programs.sql',
    );
    expect(programFile.existsSync(), isTrue, reason: '20261113001 migration must exist');
    programSql = programFile.readAsStringSync();
  });

  group('inventory_goods_receipts SQL contract', () {
    test('receipt_tables_rls_revoked', () {
      for (final t in [
        'goods_receipts',
        'goods_receipt_lines',
        'goods_receipt_lots',
      ]) {
        expect(
          receiptSql,
          contains('alter table inventory.$t enable row level security'),
        );
        expect(
          receiptSql,
          contains(
            'revoke all on inventory.$t from public, anon, authenticated',
          ),
        );
      }
    });

    test('receipt_rpcs_granted', () {
      for (final f in [
        'get_goods_receipt_form_options(uuid)',
        'record_goods_receipt(uuid, text, jsonb)',
        'list_goods_receipts(uuid, uuid, integer)',
        'get_goods_receipt(uuid, uuid)',
      ]) {
        expect(
          receiptSql,
          contains('grant execute on function inventory.$f to authenticated'),
        );
      }

      expect(
        RegExp('security definer').allMatches(receiptSql).length,
        greaterThanOrEqualTo(4),
      );
      expect(
        RegExp(
          r"_assert_actor\(p_tenant_id, 'inventory\.read'\)",
        ).allMatches(receiptSql).length,
        4,
      );
    });

    test('record_idempotent', () {
      expect(receiptSql, contains('_begin_idempotency('));
      expect(receiptSql, contains('_complete_idempotency('));
      expect(receiptSql, contains("'goods_receipt.record'"));
    });

    test('record_posts_movements', () {
      expect(receiptSql, contains('_post_movements('));
      expect(receiptSql, contains("'GOODS_RECEIPT'"));
    });

    test('record_raises_new_codes', () {
      for (final code in [
        'SUPPLIER_REQUIRED',
        'SUPPLIER_INVALID',
        'RECEIPT_PROGRAM_CHANGED',
        'RECEIPT_DISCOUNT_TOO_LARGE',
      ]) {
        expect(receiptSql, contains("'$code'"));
      }
    });

    test('program_locked_checks_receipt_lines', () {
      expect(receiptSql, contains('goods_receipt_lines'));
      expect(receiptSql, contains('inventory.goods_receipt_lines'));
      expect(
        receiptSql,
        contains(
          'create or replace function inventory._program_is_locked(',
        ),
      );
    });

    test('hints_use_effective_program', () {
      expect(programSql, contains('_effective_receipt_program('));
      expect(
        programSql,
        contains(
          'create or replace function inventory._effective_receipt_program(',
        ),
      );
    });

    test('form_options_ensures_walk_in', () {
      expect(receiptSql, contains('_ensure_walk_in_supplier('));
    });

    test('receipt_no_advisory_lock', () {
      expect(receiptSql, contains("':goods_receipt_no:'"));
      expect(receiptSql, contains('pg_advisory_xact_lock('));
    });

    test('program_row_locked_for_update', () {
      expect(receiptSql, contains('for update'));
      expect(receiptSql, contains('progress_qty'));
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

