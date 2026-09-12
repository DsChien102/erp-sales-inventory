import 'dart:io';

import 'package:test/test.dart';

void main() {
  test(
    '003 pricing sales preview draft enforces scope, precedence, and policy',
    () {
      final sql = File(
        'supabase/migrations/_drafts/003_pricing_sales_working_state_preview_group_a.sql',
      ).readAsStringSync();

      expect(sql, contains('pricing.preview_sales_working_state_pricing'));
      expect(sql, contains('pricing.evaluate_sales_manual_price'));
      expect(sql, contains('p_tenant_id'));
      expect(sql, contains('p_store_id'));
      expect(sql, contains('membership_store_scopes'));
      expect(sql, contains('is_ready_to_sell'));
      expect(sql, contains('product_unit_id'));
      expect(sql, contains('customer_price_rules'));
      expect(sql, contains('manual_unit_price_minor'));
      expect(sql, contains('store/list price'));
      expect(sql, contains('override_floor_price'));
      expect(sql, contains('requires_acknowledgement'));
      expect(sql, contains('can_view_floor'));
      expect(sql, contains('preview_token'));
      expect(sql, contains('context_version'));
      expect(sql, contains('digest('));
      expect(sql, contains('jsonb_array_length'));
    },
  );
}
