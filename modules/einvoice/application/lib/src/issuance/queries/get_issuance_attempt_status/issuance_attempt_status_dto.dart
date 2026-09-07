import 'package:vet45_einvoice_domain/domain.dart';

final class IssuanceAttemptStatusDto {
  const IssuanceAttemptStatusDto({
    this.attemptId,
    required this.status,
    required this.internalFinalizationStatus,
    required this.hasElectronicInvoice,
    required this.hasActiveOperation,
    this.failureCode,
    this.lastErrorMessage,
  });

  final String? attemptId;
  final IssuanceAttemptStatus status;
  final InternalFinalizationStatus internalFinalizationStatus;
  final bool hasElectronicInvoice;
  final bool hasActiveOperation;
  final String? failureCode;
  final String? lastErrorMessage;
}
