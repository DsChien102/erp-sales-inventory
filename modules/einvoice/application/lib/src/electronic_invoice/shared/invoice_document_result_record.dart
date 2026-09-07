import 'package:vet45_einvoice_domain/domain.dart';

final class InvoiceDocumentResultRecord {
  const InvoiceDocumentResultRecord({
    required this.tenantId,
    required this.operationId,
    required this.status,
    this.downloadUrl,
    this.fileRef,
    this.checksum,
    this.accessExpiresAt,
    this.failureCode,
    this.failureMessage,
    required this.providerInteractionReference,
    required this.expectedOperationVersion,
    required this.expectedDocumentVersion,
    this.invoiceDocumentId,
    this.contentType,
    this.fileName,
    this.fileSize,
  });

  final String tenantId;
  final String operationId;
  final InvoiceDocumentStatus status;
  final String? downloadUrl;
  final String? fileRef;
  final String? checksum;
  final DateTime? accessExpiresAt;
  final String? failureCode;
  final String? failureMessage;
  final String providerInteractionReference;
  final int expectedOperationVersion;
  final int expectedDocumentVersion;
  final String? invoiceDocumentId;
  final String? contentType;
  final String? fileName;
  final int? fileSize;
}
