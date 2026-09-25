import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Sales refactor bảng 4 `sales.sales_order_draft_lines`
/// (docs/superpowers/specs/sales-schema-refactor/04-sales-order-draft-lines.md).
void main() {
  final schemaSql = _readMigration('20260830005_sales_rebuild_schema.sql');
  final draftSql = _readMigration('20260830007_sales_draft_rpcs.sql');

  test('draft lines table stores inputs as columns', () {
    final start = schemaSql.indexOf(
      'create table if not exists sales.sales_order_draft_lines (',
    );
    final table = schemaSql.substring(start, schemaSql.indexOf('\n);', start));
    expect(table, contains('manual_discount_basis_points integer,'));
    expect(table, contains('pricing_preview jsonb not null,'));
    expect(table, contains('line_note text,'));
    expect(table, isNot(contains('updated_at')));
  });

  test('write lines keeps only display and pricing keys in pricing_preview', () {
    final body = _lastFunctionBlock(draftSql, 'sales._write_draft_lines');
    final objStart = body.indexOf('v_obj := jsonb_strip_nulls(jsonb_build_object(');
    final obj = body.substring(objStart, body.indexOf('));', objStart));
    for (final key in [
      'product_sku',
      'product_name',
      'unit_code',
      'unit_name',
      'applied_unit_price_minor',
      'line_total_minor',
      'list_unit_price_minor',
      'pricing_source_code',
      'pricing_warning_codes',
      'pricing_blocking_codes',
      'needs_revalidation',
    ]) {
      expect(obj, contains("'$key'"), reason: key);
    }
    for (final key in [
      'line_id',
      'product_id',
      'product_unit_id',
      'quantity_micros',
      'manual_unit_price_minor',
      'manual_discount_minor',
      'manual_discount_basis_points',
      "'note'",
    ]) {
      expect(obj, isNot(contains(key.startsWith("'") ? key : "'$key'")), reason: key);
    }
    expect(body, contains('manual_discount_basis_points, line_note, pricing_preview'));
  });

  test('payload rebuilds legacy line keys from columns plus pricing_preview', () {
    final body = _lastFunctionBlock(draftSql, 'sales._draft_payload');
    for (final fragment in [
      "'line_id', l.id::text,",
      "'product_id', l.product_id::text,",
      "'product_unit_id', l.product_unit_id::text,",
      "'quantity_micros', l.quantity_micros,",
      "'manual_unit_price_minor', l.manual_unit_price_input_minor,",
      "'manual_discount_minor', l.manual_discount_amount_input_minor,",
      "'manual_discount_basis_points', l.manual_discount_basis_points,",
      "'note', l.line_note",
      ')) || l.pricing_preview',
      'order by l.line_sequence',
    ]) {
      expect(body, contains(fragment), reason: fragment);
    }
    expect(body, isNot(contains('jsonb_agg(pricing_preview order by')));
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
