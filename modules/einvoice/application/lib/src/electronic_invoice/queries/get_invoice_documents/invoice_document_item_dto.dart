import 'package:vet45_einvoice_domain/domain.dart';

final class InvoiceDocumentItemDto {
  const InvoiceDocumentItemDto({
    required this.documentType,
    required this.status,
    this.operationId,
    this.downloadUrl,
    this.fileRef,
    this.checksum,
    this.expiresAt,
  });

  final InvoiceDocumentType documentType;
  final InvoiceDocumentStatus status;
  final String? operationId;
  final String? downloadUrl;
  final String? fileRef;
  final String? checksum;
  final DateTime? expiresAt;
}
