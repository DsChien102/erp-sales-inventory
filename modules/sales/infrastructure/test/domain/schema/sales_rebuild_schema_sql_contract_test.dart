import 'dart:io';

import 'package:test/test.dart';

void main() {
  late final String sql;
  late final String lowerSql;

  setUpAll(() {
    sql = _draftSqlFile().readAsStringSync();
    lowerSql = sql.toLowerCase();
  });

  test('reinstalls platform messaging before creating business tables', () {
    expect(lowerSql, isNot(contains('drop schema')));
    // No runtime guard: the draft assumes a clean schema (drop first); the
    // header documents the manual-drop requirement.
    expect(lowerSql, isNot(contains('information_schema.tables')));
    expect(
      lowerSql,
      contains("select platform.install_module_messaging('sales');"),
    );

    final messaging = lowerSql.indexOf(
      "select platform.install_module_messaging('sales');",
    );
    final firstBusinessTable = lowerSql.indexOf(
      'create table if not exists sales.idempotency_records',
    );
    expect(messaging, greaterThanOrEqualTo(0));
    expect(firstBusinessTable, greaterThan(messaging));
  });

  test('rebuild creates all canonical tables idempotently (if not exists)', () {
    const canonicalTables = <String>[
      'sales_order_drafts',
      'sales_order_draft_lines',
      'sales_orders',
      'sales_order_lines',
      'sales_order_settlements',
      'sales_payment_transactions',
      'sales_order_cancellations',
      'return_exchange_orders',
      'return_exchange_lines',
      'return_exchange_valuations',
      'sales_order_return_status_projections',
      'sales_receipts',
      'sales_receipt_activities',
      'idempotency_records',
    ];
    for (final table in canonicalTables) {
      expect(lowerSql, contains('create table if not exists sales.$table'));
    }
    for (final table in _retiredTables) {
      expect(
        lowerSql,
        isNot(contains('create table if not exists sales.$table')),
        reason: table,
      );
    }
    expect(lowerSql, isNot(contains(_removedPolicyTable)));
  });

  test('omits deferred Model B handoff tables', () {
    const deferredTables = <String>[
      'integration_commands',
      'inventory_impact_requests',
      'receivable_impact_requests',
      'e_invoice_impact_requests',
    ];
    for (final table in deferredTables) {
      expect(lowerSql, isNot(contains('create table if not exists sales.$table')));
    }
  });

  test('omits checkout persistence and enforces returned-line source ownership', () {
    expect(lowerSql, isNot(contains('checkout_attempt')));
    // Composite source key: returned original line must belong to the RX source order.
    expect(
      lowerSql,
      contains('sales_order_lines_tenant_id_id_order_unique'),
    );
    expect(
      lowerSql,
      contains('return_exchange_orders_tenant_id_id_order_unique'),
    );
    expect(
      lowerSql,
      contains('return_exchange_lines_original_source_order_fk'),
    );
    expect(
      lowerSql,
      contains(
        'foreign key (tenant_id, original_sales_order_line_id, source_sales_order_id)',
      ),
    );
    expect(
      lowerSql,
      contains(
        'references sales.sales_order_lines (tenant_id, id, sales_order_id)',
      ),
    );
  });

  test('declares clean bootstrap header metadata', () {
    expect(sql, contains('-- Kind: draft'));
    expect(sql, contains('-- Intent: sales_clean_bootstrap'));
    expect(
      sql,
      contains(
        '-- Safety: idempotent; safe to re-run; no manual sales schema removal required',
      ),
    );
  });
}

const _removedPolicyTable =
    'cancellation_reason_'
    'policy';

const _retiredTables = <String>[
  'checkout_store_policies',
  'return_exchange_reservation_refs',
  'return_exchange_reason_policy',
  'return_exchange_condition_policy',
];

File _draftSqlFile() {
  const draftRelative = 'supabase/migrations/_drafts/005_sales_rebuild_schema.sql';
  const promotedRelative = 'supabase/migrations/20260830005_sales_rebuild_schema.sql';
  final candidates = [
    File(draftRelative),
    File('../../../$draftRelative'),
    File('../../../../$draftRelative'),
    File(promotedRelative),
    File('../../../$promotedRelative'),
    File('../../../../$promotedRelative'),
  ];
  for (final candidate in candidates) {
    if (candidate.existsSync()) {
      return candidate;
    }
  }
  return candidates.first;
}
