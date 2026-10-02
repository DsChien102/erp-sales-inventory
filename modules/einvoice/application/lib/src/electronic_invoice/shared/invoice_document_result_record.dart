import 'package:vet45_einvoice_domain/domain.dart';

final class InvoiceDocumentResultRecord {
  const InvoiceDocumentResultRecord({
    required this.tenantId,
    required this.electronicInvoiceId,
    required this.documentType,
    required this.requestId,
    required this.status,
    this.fileRef,
    this.checksum,
    this.failureCode,
    this.failureMessage,
    this.failureSource,
  });

  final String tenantId;
  final String electronicInvoiceId;
  final InvoiceDocumentType documentType;
  final String requestId;
  final InvoiceDocumentStatus status;
  final String? fileRef;
  final String? checksum;
  final String? failureCode;
  final String? failureMessage;
  final FailureSource? failureSource;
}
