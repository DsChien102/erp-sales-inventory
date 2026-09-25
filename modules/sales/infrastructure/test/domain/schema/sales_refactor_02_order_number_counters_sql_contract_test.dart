import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Sales refactor bảng 2 `sales.sales_order_number_counters`
/// (docs/superpowers/specs/sales-schema-refactor/02-sales-order-number-counters.md).
void main() {
  final schemaSql = _readMigration('20260830005_sales_rebuild_schema.sql');
  final checkoutSql = _readMigration('20260830008_sales_checkout_rpcs.sql');

  test('counter table keeps store-scoped key without updated_at', () {
    final start = schemaSql.indexOf(
      'create table if not exists sales.sales_order_number_counters (',
    );
    final table = schemaSql.substring(start, schemaSql.indexOf('\n);', start));
    expect(table, contains('primary key (tenant_id, store_id, period_key)'));
    expect(table, contains('yyyymmdd'));
    expect(table, isNot(contains('yyyymm bucket')));
    expect(table, contains('last issued'));
    expect(table, isNot(contains('updated_at')));
  });

  test('finalize upsert no longer touches updated_at', () {
    final body = _lastFunctionBlock(checkoutSql, 'sales.finalize_sales_order');
    expect(
      body,
      contains(
        'do update set next_value = sales.sales_order_number_counters.next_value + 1\n',
      ),
    );
    expect(body, isNot(contains('next_value + 1, updated_at = now()')));
    expect(
      body,
      contains("v_order_code := 'DH' || v_period || lpad(v_seq_no::text, 4, '0');"),
    );
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
