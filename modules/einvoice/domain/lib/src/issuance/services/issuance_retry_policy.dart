import '../enums/internal_finalization_status.dart';
import '../enums/issuance_attempt_status.dart';

/// Pure domain policy determining whether an issuance retry is permitted.
abstract final class IssuanceRetryPolicy {
  /// Returns `true` if and only if:
  /// - [latestStatus] is [IssuanceAttemptStatus.failed] (definite failure)
  /// - [internalFinalizationStatus] is [InternalFinalizationStatus.pending]
  /// - [hasElectronicInvoice] is `false`
  /// - [hasActiveOperation] is `false`
  static bool isAllowed({
    required IssuanceAttemptStatus latestStatus,
    required InternalFinalizationStatus internalFinalizationStatus,
    required bool hasElectronicInvoice,
    required bool hasActiveOperation,
  }) {
    if (latestStatus != IssuanceAttemptStatus.failed) {
      return false;
    }
    if (internalFinalizationStatus != InternalFinalizationStatus.pending) {
      return false;
    }
    if (hasElectronicInvoice) {
      return false;
    }
    if (hasActiveOperation) {
      return false;
    }
    return true;
  }
}
