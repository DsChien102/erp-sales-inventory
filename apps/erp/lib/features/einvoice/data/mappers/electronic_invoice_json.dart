import '../models.dart';

abstract final class EInvoiceDocumentJson {
  static OfficialInvoiceViewDto officialViewFromRow(Map<String, dynamic> row) {
    final status = mapDocumentStatus(row['status'] as String);
    final expiresAt = _parseDateTime(row['expires_at']);
    final includeViewer = _shouldIncludeViewerFields(
      status: status,
      expiresAt: expiresAt,
    );
    return OfficialInvoiceViewDto(
      operationId: row['operation_id'] as String?,
      status: status,
      viewerUrl: includeViewer ? row['viewer_url'] as String? : null,
      token: includeViewer ? row['viewer_token'] as String? : null,
      expiresAt: includeViewer ? expiresAt : null,
    );
  }

  static InvoiceDocumentRetrievalDto documentRetrievalFromRow(
    Map<String, dynamic> row,
  ) {
    return InvoiceDocumentRetrievalDto(
      operationId: row['request_id'] as String?,
      status: mapDocumentStatus(row['status'] as String),
      fileRef: row['storage_reference'] as String?,
      checksum: row['checksum'] as String?,
    );
  }

  static ElectronicInvoiceDetailDto detailFromRow(Map<String, dynamic> row) {
    final officialStatusRaw = row['official_view_status'] as String?;
    final officialStatus = officialStatusRaw == null
        ? null
        : mapDocumentStatus(officialStatusRaw);
    final officialExpiresAt = _parseDateTime(row['official_viewer_expires_at']);
    final includeViewer =
        officialStatus != null &&
        _shouldIncludeViewerFields(
          status: officialStatus,
          expiresAt: officialExpiresAt,
        );
    return ElectronicInvoiceDetailDto(
      electronicInvoiceId: row['electronic_invoice_id'] as String,
      salesOrderId: row['sales_order_id'] as String,
      invoiceNumber: row['invoice_number'] as String?,
      providerRef: row['provider_ref'] as String?,
      issuedAt: _parseDateTime(row['issued_at']),
      officialViewOperationId: row['official_view_operation_id'] as String?,
      officialViewStatus: officialStatus,
      officialViewerUrl: includeViewer
          ? row['official_viewer_url'] as String?
          : null,
      officialViewerToken: includeViewer
          ? row['official_viewer_token'] as String?
          : null,
      officialViewerExpiresAt: includeViewer ? officialExpiresAt : null,
      officialViewFailureCode: row['official_view_failure_code'] as String?,
    );
  }

  static InvoiceDocumentsDto documentsFromRow(Map<String, dynamic> row) {
    return InvoiceDocumentsDto(
      pdfAvailable: row['pdf_available'] as bool? ?? false,
      xmlAvailable: row['xml_available'] as bool? ?? false,
      retrievalStatus: mapDocumentStatus(row['retrieval_status'] as String),
      pdf: _documentItemFromRow(
        documentType: InvoiceDocumentType.pdf,
        operationId: row['pdf_operation_id'] as String?,
        statusRaw: row['pdf_status'] as String?,
        storageReference: row['pdf_storage_reference'] as String?,
        checksum: row['pdf_checksum'] as String?,
        failureCode: row['pdf_failure_code'] as String?,
      ),
      xml: _documentItemFromRow(
        documentType: InvoiceDocumentType.xml,
        operationId: row['xml_operation_id'] as String?,
        statusRaw: row['xml_status'] as String?,
        storageReference: row['xml_storage_reference'] as String?,
        checksum: row['xml_checksum'] as String?,
        failureCode: row['xml_failure_code'] as String?,
      ),
    );
  }

  static InvoiceDocumentItemDto? _documentItemFromRow({
    required InvoiceDocumentType documentType,
    required String? operationId,
    required String? statusRaw,
    required String? storageReference,
    required String? checksum,
    required String? failureCode,
  }) {
    if (statusRaw == null) {
      return null;
    }
    return InvoiceDocumentItemDto(
      documentType: documentType,
      status: mapDocumentStatus(statusRaw),
      operationId: operationId,
      fileRef: storageReference,
      checksum: checksum,
      failureCode: failureCode,
    );
  }

  static InvoiceDocumentStatus mapDocumentStatus(String raw) {
    switch (raw.toUpperCase()) {
      case 'PENDING':
        return InvoiceDocumentStatus.pending;
      case 'AVAILABLE':
        return InvoiceDocumentStatus.available;
      case 'FAILED':
        return InvoiceDocumentStatus.failed;
      case 'CHECK_REQUIRED':
        return InvoiceDocumentStatus.checkRequired;
      default:
        throw FormatException('Unknown invoice document status: $raw');
    }
  }

  static InvoiceDocumentType mapDocumentType(String raw) {
    switch (raw.toUpperCase()) {
      case 'PDF':
        return InvoiceDocumentType.pdf;
      case 'XML':
        return InvoiceDocumentType.xml;
      default:
        throw FormatException('Unknown invoice document type: $raw');
    }
  }

  static String documentTypeToRpc(InvoiceDocumentType type) {
    return switch (type) {
      InvoiceDocumentType.pdf => 'PDF',
      InvoiceDocumentType.xml => 'XML',
    };
  }

  static bool _shouldIncludeViewerFields({
    required InvoiceDocumentStatus status,
    required DateTime? expiresAt,
  }) {
    return status == InvoiceDocumentStatus.available &&
        expiresAt != null &&
        expiresAt.isAfter(DateTime.now());
  }

  static DateTime? _parseDateTime(Object? raw) {
    if (raw == null) {
      return null;
    }
    return DateTime.parse(raw as String);
  }
}

