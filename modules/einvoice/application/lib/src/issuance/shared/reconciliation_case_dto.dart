import 'package:vet45_einvoice_domain/domain.dart';

/// Reconciliation case state returned by open/resolve commands.
final class ReconciliationCaseDto {
  const ReconciliationCaseDto({
    required this.caseId,
    required this.attemptId,
    required this.status,
  });

  final String caseId;
  final String attemptId;
  final ReconciliationCaseStatus status;
}
