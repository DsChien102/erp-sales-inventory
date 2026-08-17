import 'package:vet45_einvoice_domain/domain.dart';

final class InvoiceDocumentsDto {
  const InvoiceDocumentsDto({
    required this.pdfAvailable, required this.xmlAvailable, required this.retrievalStatus,
  });

  final bool pdfAvailable;
  final bool xmlAvailable;
  final InvoiceDocumentStatus retrievalStatus;
}
