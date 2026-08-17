import '../../../shared/electronic_invoice_dto.dart';

final class RecoverInternalFinalizationResultDto {
  const RecoverInternalFinalizationResultDto({
    required this.invoice,
  });

  final ElectronicInvoiceDto invoice;
}
