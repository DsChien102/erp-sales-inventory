import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String salesLinkSql;
  late String stockPolicySql;

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

