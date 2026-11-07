import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/logic/sales_transaction_result_issue.dart';

/// Translates stable application error codes into presentation-safe issues.
final class SalesTransactionResultMapper {
  const SalesTransactionResultMapper._();

  static SalesTransactionResultIssue issueFor(Object error) {
    if (error is AppException) {
      return switch (error.code) {
        'UNCERTAIN_RESULT' => SalesTransactionResultIssue.uncertainResult,
        'CHECKOUT_BLOCKED' => SalesTransactionResultIssue.checkoutBlocked,
        'NOT_FOUND' => SalesTransactionResultIssue.notFound,
        'NO_PERMISSION' || 'DATA_SCOPE_DENIED' => SalesTransactionResultIssue.permissionDenied,
        'PROJECTION_PENDING' => SalesTransactionResultIssue.projectionPending,
        'STALE_VERSION' => SalesTransactionResultIssue.staleVersion,
        'IDEMPOTENCY_CONFLICT' => SalesTransactionResultIssue.idempotencyConflict,
        'CONTEXT_INVALID' => SalesTransactionResultIssue.contextInvalid,
        'DEPENDENCY_UNAVAILABLE' => SalesTransactionResultIssue.dependencyUnavailable,
        _ => SalesTransactionResultIssue.transportFailure,
      };
    }
    return SalesTransactionResultIssue.transportFailure;
  }
}
