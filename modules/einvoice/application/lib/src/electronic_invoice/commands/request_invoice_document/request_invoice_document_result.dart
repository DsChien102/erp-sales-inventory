import 'package:vet45_einvoice_domain/domain.dart';

final class InvoiceDocumentRetrievalDto {
  const InvoiceDocumentRetrievalDto({
    this.operationId,
    this.status = InvoiceDocumentStatus.pending,
    this.downloadUrl,
    this.fileRef,
    this.checksum,
  });

  /// Stable identity for the per-invoice, per-document retrieval operation.
  final String? operationId;
  final InvoiceDocumentStatus status;
  final String? downloadUrl;
  final String? fileRef;
  final String? checksum;
}
