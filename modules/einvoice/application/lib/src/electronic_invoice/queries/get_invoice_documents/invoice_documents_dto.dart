import 'package:vet45_einvoice_domain/domain.dart';

import 'invoice_document_item_dto.dart';

final class InvoiceDocumentsDto {
  const InvoiceDocumentsDto({
    required this.pdfAvailable,
    required this.xmlAvailable,
    required this.retrievalStatus,
    this.pdf,
    this.xml,
  });

  final bool pdfAvailable;
  final bool xmlAvailable;
  final InvoiceDocumentStatus retrievalStatus;
  final InvoiceDocumentItemDto? pdf;
  final InvoiceDocumentItemDto? xml;
}
