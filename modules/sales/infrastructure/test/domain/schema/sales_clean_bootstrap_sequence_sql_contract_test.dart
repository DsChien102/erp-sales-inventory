import 'dart:io';

import 'package:test/test.dart';

/// Promoted Sales bootstrap sequence (drafts were promoted; `_drafts/` is empty).
const salesBootstrapFiles = <String>[
  '20260830005_sales_rebuild_schema.sql',
  '20260830006_sales_shared_rpc_helpers.sql',
  '20260830007_sales_draft_rpcs.sql',
  '20260830008_sales_checkout_rpcs.sql',
  '20260830009_sales_settlement_rpcs.sql',
  '20260830010_sales_inquiry_receipt_rpcs.sql',
  '20260830011_sales_adjustment_cancellation_rpcs.sql',
  '20260830012_sales_return_exchange_session_rpcs.sql',
  '20260830013_sales_return_exchange_settlement_rpcs.sql',
  '20260830014_sales_return_exchange_confirmation_rpcs.sql',
  '20260830015_sales_integration_rpcs.sql',
];

void main() {
  test('active Sales bootstrap migrations never drop the sales schema', () {
    for (final file in salesBootstrapFiles) {
      expect(
        _readMigration(file).toLowerCase(),
        isNot(contains('drop schema')),
        reason: file,
      );
    }
  });

  test('only 005 owns Sales table and column DDL', () {
    final forbidden = RegExp(
      r'^(create table|alter table|drop table|drop function)\b',
      caseSensitive: false,
      multiLine: true,
    );
    for (final file in salesBootstrapFiles.skip(1)) {
      expect(forbidden.hasMatch(_readMigration(file)), isFalse, reason: file);
    }
  });

  test('active Sales bootstrap migrations contain no legacy cleanup authorities', () {
    const legacyObjects = <String>[
      'sales.outbox ',
      'sales.idempotency_keys',
      'sales.return_exchange_operation_idempotency',
      'sales.integration_operation_results',
      'sales.return_exchange_settlement_plans',
      'sales.return_exchange_confirmations',
      'sales.return_exchange_reservation_release_requests',
    ];
    final sql = salesBootstrapFiles.map(_readMigration).join('\n').toLowerCase();
    for (final object in legacyObjects) {
      expect(sql, isNot(contains(object)), reason: object);
    }
  });
}

String _readMigration(String fileName) {
  final relativePath = 'supabase/migrations/$fileName';
  final candidates = [
    File(relativePath),
    File('../../../$relativePath'),
    File('../../../../$relativePath'),
  ];
  for (final candidate in candidates) {
    if (candidate.existsSync()) {
      return candidate.readAsStringSync();
    }
  }
  throw StateError('Missing migration $relativePath');
}
