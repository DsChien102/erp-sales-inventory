import 'dart:io';

import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';

void main() {
  group('IssueInvoiceCommand contract', () {
    test('source unavailable is a blocker, not top-level code', () {
      expect(EInvoiceBlockedCodes.issuanceNotReady, 'ISSUANCE_NOT_READY');
      expect(
        EInvoiceIssuanceBlockers.sourceSnapshotUnavailable,
        'SOURCE_SNAPSHOT_UNAVAILABLE',
      );
    });

    test('same key with changed intent is a top-level idempotency conflict', () {
      expect(EInvoiceBlockedCodes.idempotencyConflict, 'IDEMPOTENCY_CONFLICT');
    });

    test('einvoice_blocked_codes does not declare issuance blocker reasons', () {
      final fileInPkg = File('lib/src/shared/einvoice_blocked_codes.dart');
      final fileFromRoot = File(
        'modules/einvoice/application/lib/src/shared/einvoice_blocked_codes.dart',
      );
      final file = fileInPkg.existsSync() ? fileInPkg : fileFromRoot;
      final source = file.readAsStringSync();
      expect(source, isNot(contains('SOURCE_SNAPSHOT_UNAVAILABLE')));
      expect(source, isNot(contains('BUYER_SOURCE_UNAVAILABLE')));
    });
  });
}
