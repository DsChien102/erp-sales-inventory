import 'cancellation_reason_dto.dart';
import 'sales_order_cancellation_result_dto.dart';

final class SalesOrderCancellationDetailDto {
  const SalesOrderCancellationDetailDto({
    required this.result,
    required this.reason,
    required this.cancelledAt,
    required this.cancelledByActorId,
    required this.netConfirmedCollectionMinor,
    this.cancelledByActorName = '',
  });

  final SalesOrderCancellationResultDto result;
  final CancellationReasonDto reason;
  final DateTime cancelledAt;

  /// Historical actor identifier from the cancellation decision row.
  final String cancelledByActorId;

  /// Current display name resolved at read time from IAM/auth.
  ///
  /// Empty when the backend does not have a displayable name.
  final String cancelledByActorName;

  /// Net confirmed collection at cancellation time (minor units) from the
  /// authoritative decision row. `0` for a valid refund-free cancellation.
  final int netConfirmedCollectionMinor;
}
