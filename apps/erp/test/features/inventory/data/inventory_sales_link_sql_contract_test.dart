import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String salesLinkSql;
  late String stockPolicySql;
  late String salesSchemaSql;
  late String salesCheckoutRpcsSql;
  late String salesBuyerInvoiceSql;
  late String salesNormalizeSql;

  setUpAll(() {
    final repoRoot = _findRepoRoot();
    final salesLinkFile = File(
      '${repoRoot.path}/supabase/migrations/20261115001_inventory_sales_link.sql',
    );
    expect(salesLinkFile.existsSync(), isTrue, reason: '20261115001 migration must exist');
    salesLinkSql = salesLinkFile.readAsStringSync();

    final stockPolicyFile = File(
      '${repoRoot.path}/supabase/migrations/20261111001_inventory_stock_policy.sql',
    );
    expect(stockPolicyFile.existsSync(), isTrue, reason: '20261111001 migration must exist');
    stockPolicySql = stockPolicyFile.readAsStringSync();

    final salesSchemaFile = File(
      '${repoRoot.path}/supabase/migrations/20260830005_sales_rebuild_schema.sql',
    );
    expect(salesSchemaFile.existsSync(), isTrue, reason: '20260830005 migration must exist');
    salesSchemaSql = salesSchemaFile.readAsStringSync();

    final salesCheckoutRpcsFile = File(
      '${repoRoot.path}/supabase/migrations/20260830008_sales_checkout_rpcs.sql',
    );
    expect(salesCheckoutRpcsFile.existsSync(), isTrue, reason: '20260830008 migration must exist');
    salesCheckoutRpcsSql = salesCheckoutRpcsFile.readAsStringSync();

    final salesBuyerInvoiceFile = File(
      '${repoRoot.path}/supabase/migrations/20261031017_sales_buyer_invoice_snapshot.sql',
    );
    expect(salesBuyerInvoiceFile.existsSync(), isTrue, reason: '20261031017 migration must exist');
    salesBuyerInvoiceSql = salesBuyerInvoiceFile.readAsStringSync();

    final salesNormalizeFile = File(
      '${repoRoot.path}/supabase/migrations/20260904001_sales_normalize_outbox_and_commands.sql',
    );
    expect(salesNormalizeFile.existsSync(), isTrue, reason: '20260904001 migration must exist');
    salesNormalizeSql = salesNormalizeFile.readAsStringSync();
  });

  group('inventory_sales_link SQL contract - Task 1', () {
    test('helpers_defined_and_revoked', () {
      final fns = [
        '_warehouse_for_store',
        '_stock_shortages',
        '_issue_for_sale',
        '_reversal_kind',
        '_reverse_sale',
      ];
      for (final fn in fns) {
        expect(
          salesLinkSql,
          contains('create or replace function inventory.$fn('),
          reason: 'Function inventory.$fn must be defined',
        );
        expect(
          salesLinkSql,
          contains('revoke all on function inventory.$fn'),
          reason: 'Function inventory.$fn must have revoke all',
        );
        expect(
          salesLinkSql.contains('grant execute on function inventory.$fn'),
          isFalse,
          reason: 'Function inventory.$fn must NOT be granted execute',
        );
      }
      expect(
        RegExp('security definer').allMatches(salesLinkSql).length,
        greaterThanOrEqualTo(5),
      );
    });

    test('issue_locks_before_choosing_lots', () {
      final issueIndex = salesLinkSql.indexOf('function inventory._issue_for_sale');
      expect(issueIndex, isNonNegative);
      final issueBody = salesLinkSql.substring(issueIndex);
      final lockPos = issueBody.indexOf('pg_advisory_xact_lock');
      final stockBalancesPos = issueBody.indexOf('from inventory.stock_balances');
      expect(lockPos, isNonNegative, reason: 'Must take advisory lock');
      expect(stockBalancesPos, isNonNegative, reason: 'Must query stock_balances');
      expect(
        lockPos,
        lessThan(stockBalancesPos),
        reason: 'pg_advisory_xact_lock must be acquired before querying stock_balances',
      );
    });

    test('issue_posts_sale', () {
      expect(salesLinkSql, contains('_post_movements('));
      expect(salesLinkSql, contains("'SALE'"));
    });

    test('reverse_uses_reversal_kind', () {
      final reverseIndex = salesLinkSql.indexOf('function inventory._reverse_sale');
      expect(reverseIndex, isNonNegative);
      final reverseBody = salesLinkSql.substring(reverseIndex);
      expect(reverseBody, contains('_reversal_kind('));
    });

    test('fefo_skips_expired', () {
      final issueIndex = salesLinkSql.indexOf('function inventory._issue_for_sale');
      expect(issueIndex, isNonNegative);
      final issueBody = salesLinkSql.substring(issueIndex);
      expect(issueBody, contains('_lot_expiry_end('));
    });

    test('stock_rows_product_filter', () {
      expect(stockPolicySql, contains('p_product_ids uuid[] default null'));
      final matches = RegExp(r'create or replace function inventory\._product_stock_rows').allMatches(stockPolicySql);
      expect(matches.length, equals(1), reason: 'Must have exactly one _product_stock_rows function (no overload)');
    });
  });

  group('inventory_sales_link SQL contract - Task 2', () {
    test('finalize_issues_stock', () {
      expect(salesBuyerInvoiceSql, contains('inventory._issue_for_sale('));
      expect(salesBuyerInvoiceSql, contains("'SALES_ORDER'"));
      expect(salesBuyerInvoiceSql, contains("'INSUFFICIENT_STOCK'"));
      expect(salesBuyerInvoiceSql, contains("'blockedMessage'"));
    });

    test('precheck_checks_shortages', () {
      expect(salesCheckoutRpcsSql, contains('inventory._stock_shortages('));
    });

    test('cancellation_reverses', () {
      final lastCancelIndex = salesNormalizeSql.lastIndexOf('create or replace function sales.confirm_sales_order_cancellation');
      expect(lastCancelIndex, isNonNegative);
      final cancelBody = salesNormalizeSql.substring(lastCancelIndex);
      expect(cancelBody, contains('inventory._reverse_sale('));
      expect(cancelBody, contains("'SALES_CANCELLATION'"));
    });

    test('return_exchange_posts_both', () {
      final lastRetExIndex = salesNormalizeSql.lastIndexOf('create or replace function sales.confirm_return_exchange');
      expect(lastRetExIndex, isNonNegative);
      final retExBody = salesNormalizeSql.substring(lastRetExIndex);
      final reversePos = retExBody.indexOf('inventory._reverse_sale(');
      final issuePos = retExBody.indexOf('inventory._issue_for_sale(');
      expect(reversePos, isNonNegative, reason: 'Must call _reverse_sale');
      expect(issuePos, isNonNegative, reason: 'Must call _issue_for_sale');
      expect(reversePos, lessThan(issuePos), reason: '_reverse_sale must precede _issue_for_sale');
    });

    test('cogs_columns', () {
      for (final col in [
        'cogs_amount_vnd',
        'cogs_unit_cost',
        'cost_version_id',
        'cogs_is_provisional',
      ]) {
        expect(salesSchemaSql, contains(col), reason: 'Column $col must exist in sales schema rebuild');
      }
    });
  });
}

Directory _findRepoRoot() {
  var dir = Directory.current;
  while (!File('${dir.path}/supabase/config.toml').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('Cannot find repo root from ${Directory.current.path}');
    }
    dir = parent;
  }
  return dir;
}

