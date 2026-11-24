import 'einvoice_enums.dart';

/// Official invoice viewer data.
final class OfficialInvoiceViewDto {
  const OfficialInvoiceViewDto({
    this.operationId,
    this.status = InvoiceDocumentStatus.pending,
    this.viewerUrl,
    this.token,
    this.expiresAt,
  });

  /// Stable async operation identity. Replays return the same operation.
  final String? operationId;
  final InvoiceDocumentStatus status;
  final String? viewerUrl;
  final String? token;
  final DateTime? expiresAt;
}

/// Result of requesting an invoice document (PDF/XML).
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

/// Electronic invoice detail read model.
final class ElectronicInvoiceDetailDto {
  const ElectronicInvoiceDetailDto({
    required this.electronicInvoiceId,
    required this.salesOrderId,
    this.invoiceNumber,
    this.providerRef,
    this.issuedAt,
    this.officialViewOperationId,
    this.officialViewStatus,
    this.officialViewerUrl,
    this.officialViewerToken,
    this.officialViewerExpiresAt,
    this.officialViewFailureCode,
  });

  final String electronicInvoiceId;
  final String salesOrderId;
  final String? invoiceNumber;
  final String? providerRef;
  final DateTime? issuedAt;
  final String? officialViewOperationId;
  final InvoiceDocumentStatus? officialViewStatus;
  final String? officialViewerUrl;
  final String? officialViewerToken;
  final DateTime? officialViewerExpiresAt;
  final String? officialViewFailureCode;
}

/// Single document item (PDF or XML).
final class InvoiceDocumentItemDto {
  const InvoiceDocumentItemDto({
    required this.documentType,
    required this.status,
    this.operationId,
    this.downloadUrl,
    this.fileRef,
    this.checksum,
    this.expiresAt,
    this.failureCode,
  });

  final InvoiceDocumentType documentType;
  final InvoiceDocumentStatus status;
  final String? operationId;
  final String? downloadUrl;
  final String? fileRef;
  final String? checksum;
  final DateTime? expiresAt;
  final String? failureCode;
}

/// Documents aggregate (PDF and XML).
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

