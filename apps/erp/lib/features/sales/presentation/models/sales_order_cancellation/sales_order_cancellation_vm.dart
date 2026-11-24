import 'package:equatable/equatable.dart';

/// S27 cancellation result view for SG-08 (composed as an independent section).
class SalesOrderCancellationVm extends Equatable {
  const SalesOrderCancellationVm({
    required this.cancellationId,
    required this.reason,
    required this.statusLabel,
    required this.isProcessing,
    required this.cancelledByActorId,
    required this.cancelledAtFormatted,
    required this.netConfirmedCollectionFormatted,
    this.cancelledByActorName = '',
  });

  final String cancellationId;
  final String reason;
  final String statusLabel;
  final bool isProcessing;

  /// Historical actor identifier from the cancellation record.
  final String cancelledByActorId;

  /// Current display name resolved by the backend at read time.
  final String cancelledByActorName;

  final String cancelledAtFormatted;
  final String netConfirmedCollectionFormatted;

  @override
  List<Object?> get props => [
    cancellationId,
    reason,
    statusLabel,
    isProcessing,
    cancelledByActorId,
    cancelledByActorName,
    cancelledAtFormatted,
    netConfirmedCollectionFormatted,
  ];
}
