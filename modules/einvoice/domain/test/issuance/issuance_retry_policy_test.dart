import 'package:test/test.dart';
import 'package:vet45_einvoice_domain/domain.dart';

void main() {
  group('IssuanceRetryPolicy', () {
    test(
      'allows retry when latest attempt failed, pending finalization, no invoice, and no active operation',
      () {
        final allowed = IssuanceRetryPolicy.isAllowed(
          latestStatus: IssuanceAttemptStatus.failed,
          internalFinalizationStatus: InternalFinalizationStatus.pending,
          hasElectronicInvoice: false,
          hasActiveOperation: false,
        );

        expect(allowed, isTrue);
      },
    );

    test('disallows retry when latest status is not failed', () {
      const nonFailedStatuses = [
        IssuanceAttemptStatus.preparing,
        IssuanceAttemptStatus.submitted,
        IssuanceAttemptStatus.waitingResult,
        IssuanceAttemptStatus.reconciling,
        IssuanceAttemptStatus.succeeded,
      ];

      for (final status in nonFailedStatuses) {
        final allowed = IssuanceRetryPolicy.isAllowed(
          latestStatus: status,
          internalFinalizationStatus: InternalFinalizationStatus.pending,
          hasElectronicInvoice: false,
          hasActiveOperation: false,
        );

        expect(
          allowed,
          isFalse,
          reason: 'Status $status should not allow retry',
        );
      }
    });

    test('disallows retry when internal finalization is not pending', () {
      final allowedCompleted = IssuanceRetryPolicy.isAllowed(
        latestStatus: IssuanceAttemptStatus.failed,
        internalFinalizationStatus: InternalFinalizationStatus.completed,
        hasElectronicInvoice: false,
        hasActiveOperation: false,
      );
      expect(allowedCompleted, isFalse);

      final allowedUnresolved = IssuanceRetryPolicy.isAllowed(
        latestStatus: IssuanceAttemptStatus.failed,
        internalFinalizationStatus: InternalFinalizationStatus.unresolved,
        hasElectronicInvoice: false,
        hasActiveOperation: false,
      );
      expect(allowedUnresolved, isFalse);
    });

    test('disallows retry when electronic invoice already exists', () {
      final allowed = IssuanceRetryPolicy.isAllowed(
        latestStatus: IssuanceAttemptStatus.failed,
        internalFinalizationStatus: InternalFinalizationStatus.pending,
        hasElectronicInvoice: true,
        hasActiveOperation: false,
      );

      expect(allowed, isFalse);
    });

    test('disallows retry when active operation is in progress', () {
      final allowed = IssuanceRetryPolicy.isAllowed(
        latestStatus: IssuanceAttemptStatus.failed,
        internalFinalizationStatus: InternalFinalizationStatus.pending,
        hasElectronicInvoice: false,
        hasActiveOperation: true,
      );

      expect(allowed, isFalse);
    });

    test('disallows retry when multiple blocking conditions are present', () {
      final allowed = IssuanceRetryPolicy.isAllowed(
        latestStatus: IssuanceAttemptStatus.reconciling,
        internalFinalizationStatus: InternalFinalizationStatus.unresolved,
        hasElectronicInvoice: true,
        hasActiveOperation: true,
      );

      expect(allowed, isFalse);
    });
  });
}
