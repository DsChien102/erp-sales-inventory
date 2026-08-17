import 'package:vet45_einvoice_domain/domain.dart';

final class RecordIssuanceResultDto {
  const RecordIssuanceResultDto({
    required this.attemptStatus, this.electronicInvoiceId,
  });

  final IssuanceAttemptStatus attemptStatus;
  final String? electronicInvoiceId;
}
