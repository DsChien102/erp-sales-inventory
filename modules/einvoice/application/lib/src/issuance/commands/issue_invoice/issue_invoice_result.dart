import 'package:vet45_einvoice_domain/domain.dart';

final class IssueInvoiceResultDto {
  const IssueInvoiceResultDto({
    required this.issuanceId, required this.attemptId, required this.status,
  });

  final String issuanceId;
  final String attemptId;
  final IssuanceAttemptStatus status;
}
