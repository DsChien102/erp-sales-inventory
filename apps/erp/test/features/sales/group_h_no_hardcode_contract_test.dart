import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static guard: the Group H (SG-10 cancellation) production path must not
/// regress to hardcoded versions, reasons, mutation metadata, or refund/restock
/// controls.
///
/// Scope is an explicit file list (the `idemp_`/`hash_`/`corr_` tokens are broad
/// substrings) — never a directory sweep, so unrelated groups are not scanned.
void main() {
  const groupHFiles = <String>[
    'apps/erp/lib/features/sales/presentation/bloc/sales_order/sales_order_detail_post_sale_actions.dart',
    'apps/erp/lib/features/sales/presentation/support/sales_order_cancellation_attempt_factory.dart',
    'apps/erp/lib/features/sales/presentation/widgets/sales_order_detail_cancel_reason_card.dart',
  ];

  const forbidden = <String>[
    'expectedVersion: 1',
    'expectedSettlementVersion: 1',
    'CUSTOMER_CHANGE_MIND',
    'idemp_',
    'hash_',
    'corr_',
    'orderId.toUpperCase()',
    'catch (_) {}',
    'refundPayment',
    'restockInventory',
  ];

  group('Group H no-hardcode guard', () {
    for (final relativePath in groupHFiles) {
      test('$relativePath is free of hardcoded Group H tokens', () {
        final source = _readRepoFile(relativePath);
        for (final token in forbidden) {
          expect(
            source.contains(token),
            isFalse,
            reason: '$relativePath must not contain "$token".',
          );
        }
      });
    }
  });
}

String _readRepoFile(String relativePath) {
  final candidates = <File>[
    File(relativePath),
    File('../../$relativePath'),
    File('../../../$relativePath'),
  ];
  for (final candidate in candidates) {
    if (candidate.existsSync()) return candidate.readAsStringSync();
  }
  throw StateError('Could not locate $relativePath from ${Directory.current.path}');
}
