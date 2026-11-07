import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _appSalesRpcNames = [
  'cancel_return_exchange',
  'cancel_sales_order_draft',
  'confirm_return_exchange',
  'confirm_sales_order_cancellation',
  'evaluate_return_exchange_valuation',
  'finalize_sales_order',
  'generate_sales_receipt',
  'get_available_post_sale_actions',
  'get_checkout_result',
  'get_return_exchange_detail',
  'get_returnable_order_lines',
  'get_sales_order',
  'get_sales_order_cancellation',
  'get_sales_order_detail',
  'get_sales_order_draft_for_restore',
  'get_sales_order_original_receipt',
  'get_sales_order_payment_summary',
  'get_sales_order_payment_transactions',
  'get_sales_order_return_summary',
  'get_sales_order_settlement',
  'get_sales_order_timeline',
  'get_sales_receipt',
  'list_sales_order_drafts',
  'list_sales_orders',
  'precheck_return_exchange',
  'precheck_sales_order_cancellation',
  'precheck_sales_order_checkout',
  'preview_return_exchange_pricing',
  'record_sales_payment',
  'record_sales_receipt_activity',
  'save_sales_order_draft',
  'search_sales_orders',
  'start_return_exchange',
  'update_return_exchange',
  'update_sales_order_draft',
];

void main() {
  group('kept', () {
    test('keeps every RPC the app calls', () {
      final sql = _allMigrationsSql();
      expect(_appSalesRpcNames.length, 35);
      for (final rpc in _appSalesRpcNames) {
        expect(
          _definesFn(sql, 'sales', rpc),
          isTrue,
          reason: 'Expected sales.$rpc to be defined in migrations.',
        );
      }
    });

    test('app RPC list matches repositories', () {
      final repoRoot = _findRepoRoot();
      final dataDir = Directory(
        '${repoRoot.path}/apps/erp/lib/features/sales/data',
      );
      final dartFiles = dataDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final rpcCalls = <String>{};
      final pattern = RegExp(r"'sales',\s*'([a-z_]+)'", multiLine: true);
      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        for (final match in pattern.allMatches(content)) {
          rpcCalls.add(match.group(1)!);
        }
      }

      expect(rpcCalls, equals(_appSalesRpcNames.toSet()));
    });

    test('keeps RPCs TH-05 keeps unused or einvoice calls', () {
      final sql = _allMigrationsSql();
      const keptNames = [
        // Q6: app không gọi, giữ trong DB.
        'complete_return_exchange',
        'get_return_exchange_form_policy',
        'list_sales_order_cancellation_reasons',
        'audit_sales_review_invariants',
        'record_sales_refund',
        'get_order_integration_status',
        // Còn lại.
        'can_access_sales_order',
        'get_einvoice_source_snapshot',
        'settle_return_exchange_difference',
      ];
      for (final fn in keptNames) {
        expect(
          _definesFn(sql, 'sales', fn),
          isTrue,
          reason: 'Expected sales.$fn to stay defined in migrations.',
        );
      }
    });

    test('timeline and settlement guard read sales.outbox_messages', () {
      final repoRoot = _findRepoRoot();
      final inquiry = File(
        '${repoRoot.path}/supabase/migrations/'
        '20260830010_sales_inquiry_receipt_rpcs.sql',
      );
      final helpers = File(
        '${repoRoot.path}/supabase/migrations/'
        '20260830006_sales_shared_rpc_helpers.sql',
      );
      expect(inquiry.existsSync(), isTrue);
      expect(helpers.existsSync(), isTrue);
      expect(
        inquiry.readAsStringSync().contains('from sales.outbox_messages o'),
        isTrue,
        reason: 'get_sales_order_timeline must read sales.outbox_messages.',
      );
      expect(
        helpers.readAsStringSync().contains('from sales.outbox_messages'),
        isTrue,
        reason: 'settlement guard must read sales.outbox_messages.',
      );
    });

    test('outbox writers use only id, tenant_id, event_type, payload', () {
      final sql = _allMigrationsSql();
      const allowed = {
        'id',
        'tenant_id',
        'event_type',
        'payload',
        'occurred_at',
      };
      final matches = RegExp(
        r'insert into sales\.outbox_messages\s*\(([^)]*)\)',
      ).allMatches(sql).toList();
      expect(matches.length, greaterThanOrEqualTo(20));
      for (final m in matches) {
        final cols = m
            .group(1)!
            .split(',')
            .map((c) => c.trim())
            .where((c) => c.isNotEmpty)
            .toSet();
        expect(
          allowed.containsAll(cols),
          isTrue,
          reason: 'Unexpected outbox columns: ${cols.difference(allowed)}',
        );
      }

      for (final line in sql.split('\n')) {
        if (!line.contains('outbox_messages')) continue;
        for (final col in const ['processed_at', 'claim_token', 'retry_count']) {
          expect(
            line.contains(col),
            isFalse,
            reason: 'outbox_messages line must not mention $col: $line',
          );
        }
      }
    });
  });
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

String _allMigrationsSql() {
  final repoRoot = _findRepoRoot();
  final dir = Directory('${repoRoot.path}/supabase/migrations');
  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.sql') && !f.path.contains('_drafts'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return files.map((f) => f.readAsStringSync()).join('\n');
}

bool _definesFn(String sql, String schema, String name) {
  return RegExp(
    r'create\s+(or\s+replace\s+)?function\s+' +
        schema +
        r'\.' +
        name +
        r'\s*\(',
    caseSensitive: false,
  ).hasMatch(sql);
}
