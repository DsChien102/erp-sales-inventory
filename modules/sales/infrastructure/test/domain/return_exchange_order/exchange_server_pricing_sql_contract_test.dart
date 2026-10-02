import 'dart:io';

import 'package:test/test.dart';

/// Plan 2: giá món đổi do server tính qua Pricing (spec 2026-09-28 §4).
void main() {
  late String session;
  late String settlement;
  late String confirm;

  setUpAll(() {
    session = _readMigration('20260830012_sales_return_exchange_session_rpcs.sql');
    settlement = _readMigration('20260830013_sales_return_exchange_settlement_rpcs.sql');
    confirm = _lastFunctionBlock(
      _readMigration('20260904001_sales_normalize_outbox_and_commands.sql'),
      'sales.confirm_return_exchange',
    );
  });

  test('helper prices one unit with the order customer/store/currency', () {
    final fn = _lastFunctionBlock(session, 'sales._price_exchange_unit');
    expect(fn, contains('pricing.preview_sales_working_state_pricing('));
    expect(fn, contains('p_order.store_id, p_order.customer_partner_id, p_order.currency_code'));
    expect(fn, contains("'code', 'PRICING_BLOCKED'"));
    expect(session, contains('revoke all on function sales._price_exchange_unit(uuid, sales.sales_orders, uuid, uuid) from public, anon, authenticated;'));
    expect(session.indexOf('create or replace function sales._price_exchange_unit('),
        lessThan(session.indexOf('create or replace function sales.start_return_exchange(')));
  });

  test('preview RPC asserts the actor and is granted to authenticated', () {
    final fn = _lastFunctionBlock(session, 'sales.preview_return_exchange_pricing');
    expect(fn, contains("perform sales._assert_sales_actor(p_tenant_id, p_actor_id, v_order.store_id, 'sales.return_exchange.create');"));
    expect(fn, contains('sales._price_exchange_unit(p_tenant_id, v_order,'));
    expect(session, contains('grant execute on function sales.preview_return_exchange_pricing(uuid, uuid, uuid, jsonb) to authenticated;'));
  });

  test('price check helper owns PRICE_CHANGED and returns the server price', () {
    final fn = _lastFunctionBlock(session, 'sales._assert_exchange_price');
    expect(fn, contains('sales._price_exchange_unit(p_tenant_id, p_order, p_product_id, p_product_unit_id)'));
    expect(fn, contains('if v_actual_minor is distinct from p_expected_unit_price_minor then'));
    expect(fn, contains("'code', 'PRICE_CHANGED'"));
    expect(fn, contains('return v_actual_minor;'));
    expect(
      session,
      contains(
        'revoke all on function sales._assert_exchange_price(uuid, sales.sales_orders, uuid, uuid, bigint) from public, anon, authenticated;',
      ),
    );
    expect(session.indexOf('create or replace function sales._assert_exchange_price('),
        lessThan(session.indexOf('create or replace function sales.start_return_exchange(')));
  });

  group('server writes and re-checks exchange prices through the helper', () {
    test('start and update store the server price checked against the preview', () {
      for (final name in ['sales.start_return_exchange', 'sales.update_return_exchange']) {
        final fn = _lastFunctionBlock(session, name);
        expect(fn, contains('v_unit_price_minor := sales._assert_exchange_price('), reason: name);
        expect(fn, contains("(v_priced ->> 'amountMinor')::bigint"), reason: name);
        expect(fn, isNot(contains("'code', 'PRICE_CHANGED'")), reason: name);
        expect(fn, isNot(contains("v_unit_price_minor := coalesce((v_priced ->> 'amountMinor')::bigint, 0);")), reason: name);
      }
    });

    test('valuation re-checks the stored price instead of trusting the decision', () {
      final fn = _lastFunctionBlock(settlement, 'sales.evaluate_return_exchange_valuation');
      expect(fn, isNot(contains("reference_decision -> 'exchange_prices_by_product_unit_id'")));
      expect(fn, contains('perform sales._assert_exchange_price('));
      expect(fn, isNot(contains("'code', 'PRICE_CHANGED'")));
    });

    test('confirm re-checks exchange prices before completing', () {
      expect(confirm, contains("and rl.line_role = 'exchange'"));
      expect(confirm, contains('perform sales._assert_exchange_price('));
      expect(confirm, isNot(contains("'code', 'PRICE_CHANGED'")));
    });
  });
}

String _readMigration(String fileName) {
  var dir = Directory.current.absolute;
  while (!Directory('${dir.path}/supabase/migrations').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) throw StateError('Could not locate Vet45 workspace root');
    dir = parent;
  }
  return File('${dir.path}/supabase/migrations/$fileName').readAsStringSync();
}

String _lastFunctionBlock(String sql, String qualifiedName) {
  final start = sql.lastIndexOf('create or replace function $qualifiedName(');
  if (start < 0) throw StateError('$qualifiedName not found');
  final end = sql.indexOf(r'$$;', start);
  return sql.substring(start, end + 3);
}
