import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Sales refactor bảng 7
/// `sales.sales_order_return_status_projections`
/// (docs/superpowers/specs/sales-schema-refactor/07-sales-order-return-status-projections.md).
void main() {
  final schemaSql = _readMigration('20260830005_sales_rebuild_schema.sql');
  const removed = ['sold_quantity_micros', 'returned_quantity_micros', 'version'];

  test('projection table keeps 4 columns with composite primary key', () {
    final start = schemaSql.indexOf(
      'create table if not exists sales.sales_order_return_status_projections (',
    );
    final table = schemaSql.substring(start, schemaSql.indexOf('\n);', start));
    expect(table, contains('primary key (tenant_id, sales_order_id)'));
    expect(table, isNot(contains('id uuid primary key')));
    for (final column in removed) {
      expect(table, isNot(contains(column)), reason: column);
    }
  });

  final upserts = <String, String>{
    '20260904001_sales_normalize_outbox_and_commands.sql': 'sales.confirm_return_exchange',
    '20260830014_sales_return_exchange_confirmation_rpcs.sql': 'sales.complete_return_exchange',
  };
  upserts.forEach((file, fn) {
    test('$fn upserts status only', () {
      final body = _lastFunctionBlock(_readMigration(file), fn);
      final start = body.indexOf(
        'insert into sales.sales_order_return_status_projections (',
      );
      final upsert = body.substring(start, body.indexOf('updated_at = now();', start));
      for (final column in removed) {
        expect(upsert, isNot(contains(column)), reason: column);
      }
      expect(upsert, contains('return_status = excluded.return_status,'));
    });
  });

  test('audit compares stored return status with per-line recomputation', () {
    final helperSql = _readMigration('20260830006_sales_shared_rpc_helpers.sql');
    final audit = _lastFunctionBlock(helperSql, 'sales.audit_sales_review_invariants');
    expect(audit, isNot(contains('return_projection_quantity_mismatch')));
    expect(audit, contains("'return_projection_status_mismatch'"));
    expect(audit, contains('return_line.original_sales_order_line_id = order_line.id'));
    expect(
      audit,
      contains('where projection.return_status is distinct from recomputed.return_status;'),
    );
    for (final column in removed) {
      expect(audit, isNot(contains('projection.$column')), reason: column);
    }
  });

  upserts.forEach((file, fn) {
    test('$fn computes status per line and emits base quantities', () {
      final body = _lastFunctionBlock(_readMigration(file), fn);
      expect(body, contains('with per_line as ('));
      expect(body, contains('l.base_quantity_micros as sold_base,'));
      expect(body, contains('sum(rl.base_quantity_micros) as base'));
      expect(body, contains("'soldBaseQuantityMicros', v_sold_base_micros,"));
      expect(body, contains("'returnedBaseQuantityMicros', v_returned_base_micros"));
      expect(body, isNot(contains('v_sold_micros')));
      expect(body, isNot(contains("'soldQuantityMicros'")));
    });
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
