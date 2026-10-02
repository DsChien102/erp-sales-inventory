import 'dart:io';

import 'package:test/test.dart';

/// Server tự tính giá lúc chốt đơn (spec 2026-09-28 §4.2).
void main() {
  late String fn;

  setUpAll(() {
    var dir = Directory.current.absolute;
    while (!Directory('${dir.path}/supabase/migrations/_drafts').existsSync()) {
      final parent = dir.parent;
      if (parent.path == dir.path) throw StateError('Could not locate Vet45 workspace root');
      dir = parent;
    }
    final sql = File('${dir.path}/supabase/migrations/_drafts/017_sales_buyer_invoice_snapshot.sql').readAsStringSync();
    final start = sql.lastIndexOf('create or replace function sales.finalize_sales_order(');
    fn = sql.substring(start, sql.indexOf(r'$$;', start) + 3);
  });

  test('prices lines on the server with the shared pricing function', () {
    expect(fn, contains('v_pricing := pricing.preview_sales_working_state_pricing('));
    expect(fn, contains("'manual_discount_basis_points', l.value -> 'manual_discount_basis_points'"));
    expect(fn, contains("from jsonb_array_elements(p_lines) with ordinality as l(value, ordinality);"));
  });

  test('derives list price + discount only for manual discount modes', () {
    expect(fn, contains("v_is_discount_mode := (v_priced ->> 'source_code') = 'MANUAL'"));
    expect(fn, contains("v_unit_price_minor := (v_priced ->> 'list_price_minor')::bigint;"));
    expect(fn, contains('v_discount_minor := v_gross_minor - v_line_total_minor;'));
    expect(fn, contains("'MANUAL_DISCOUNT_PERCENT'"));
    expect(fn, isNot(contains("v_discount_minor := coalesce((v_commercial_line -> 'discountTotal' ->> 'amountMinor')::bigint, 0);")));
  });

  test('rejects blocked pricing and price drift', () {
    expect(fn, contains("'code', 'PRICING_BLOCKED'"));
    expect(fn, contains("'code', 'PRICE_CHANGED'"));
    expect(fn, contains("'expectedLineTotalMinor'"));
    expect(fn, isNot(contains("<> (v_line -> 'unit_price' ->> 'amount_minor')::bigint\n         or coalesce((v_commercial_line -> 'lineTotal'")));
  });

  test('persists the pricing snapshot and reports blockedCode', () {
    expect(fn, contains("'pricing_snapshot', v_pricing_snapshot"));
    expect(fn, contains('product_snapshot, product_unit_snapshot, line_note, pricing_snapshot'));
    expect(fn, contains("'PRICE_CHANGED', 'PRICING_BLOCKED'"));
    expect(fn, contains("v_result := v_result || jsonb_build_object('blockedCode', v_error_code);"));
  });
}
