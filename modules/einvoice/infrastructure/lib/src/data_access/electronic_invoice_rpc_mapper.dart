import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

abstract final class ElectronicInvoiceRpcMapper {
  static Map<String, dynamic> scopedSalesOrderParams({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) {
    return {
      'p_tenant_id': tenantId,
      'p_actor_id': actorId,
      'p_sales_order_id': salesOrderId,
    };
  }

  static Map<String, dynamic> requestDocumentParams({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
    required InvoiceDocumentType documentType,
  }) {
    return {
      'p_tenant_id': tenantId,
      'p_actor_id': actorId,
      'p_sales_order_id': salesOrderId,
      'p_document_type': documentTypeToRpc(documentType),
    };
  }

  static Map<String, dynamic> loadOfficialViewContextParams({
    required String tenantId,
    required String electronicInvoiceId,
    required String requestId,
  }) {
    return {
      'p_tenant_id': tenantId,
      'p_electronic_invoice_id': electronicInvoiceId,
      'p_request_id': requestId,
    };
  }

  static Map<String, dynamic> loadDocumentContextParams({
    required String tenantId,
    required String electronicInvoiceId,
    required InvoiceDocumentType documentType,
    required String requestId,
  }) {
    return {
      'p_tenant_id': tenantId,
      'p_electronic_invoice_id': electronicInvoiceId,
      'p_document_type': documentTypeToRpc(documentType),
      'p_request_id': requestId,
    };
  }

  static Map<String, dynamic> loadObservationContextParams({
    required String tenantId,
    required String commandId,
  }) {
    return {'p_tenant_id': tenantId, 'p_command_id': commandId};
  }

  static Map<String, dynamic> recordOfficialViewResultParams(
    OfficialViewResultRecord record,
  ) {
    return {
      'p_tenant_id': record.tenantId,
      'p_electronic_invoice_id': record.electronicInvoiceId,
      'p_request_id': record.requestId,
      'p_status': _documentStatusToRpc(record.status),
      if (record.viewerUrl != null) 'p_viewer_url': record.viewerUrl,
      if (record.viewerToken != null) 'p_viewer_token': record.viewerToken,
      if (record.expiresAt != null)
        'p_expires_at': record.expiresAt!.toUtc().toIso8601String(),
      if (record.failureCode != null) 'p_failure_code': record.failureCode,
      if (record.failureMessage != null)
        'p_failure_message': record.failureMessage,
      'p_failure_source': failureSourceToRpc(record.failureSource),
    };
  }

  static Map<String, dynamic> recordDocumentResultParams(
    InvoiceDocumentResultRecord record,
  ) {
    return {
      'p_tenant_id': record.tenantId,
      'p_electronic_invoice_id': record.electronicInvoiceId,
      'p_document_type': documentTypeToRpc(record.documentType),
      'p_request_id': record.requestId,
      'p_status': _documentStatusToRpc(record.status),
      if (record.fileRef != null) 'p_storage_reference': record.fileRef,
      if (record.checksum != null) 'p_checksum': record.checksum,
      if (record.failureCode != null) 'p_failure_code': record.failureCode,
      if (record.failureMessage != null)
        'p_failure_message': record.failureMessage,
      'p_failure_source': failureSourceToRpc(record.failureSource),
    };
  }

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

  static OfficialViewOperationContextDto officialViewContextFromRow(
    Map<String, dynamic> row,
  ) {
    return OfficialViewOperationContextDto(
      tenantId: row['tenant_id'] as String,
      electronicInvoiceId: row['electronic_invoice_id'] as String,
      requestId: row['request_id'] as String,
      status: mapDocumentStatus(row['status'] as String),
      providerConnectionId: row['provider_connection_id'] as String,
      providerInvoiceReference: row['provider_invoice_reference'] as String,
      invoiceSeries: row['invoice_series'] as String,
    );
  }

  static InvoiceDocumentOperationContextDto documentContextFromRow(
    Map<String, dynamic> row,
  ) {
    return InvoiceDocumentOperationContextDto(
      tenantId: row['tenant_id'] as String,
      electronicInvoiceId: row['electronic_invoice_id'] as String,
      documentType: mapDocumentType(row['document_type'] as String),
      requestId: row['request_id'] as String,
      status: mapDocumentStatus(row['status'] as String),
      providerConnectionId: row['provider_connection_id'] as String,
      providerInvoiceReference: row['provider_invoice_reference'] as String,
      invoiceSeries: row['invoice_series'] as String,
    );
  }

  static ProviderObservationOperationContextDto observationContextFromRow(
    Map<String, dynamic> row,
  ) {
    return ProviderObservationOperationContextDto(
      commandId: row['command_id'] as String,
      tenantId: row['tenant_id'] as String,
      electronicInvoiceId: row['electronic_invoice_id'] as String,
      providerConnectionId: row['provider_connection_id'] as String,
      providerInvoiceReference: row['provider_invoice_reference'] as String,
      invoiceSeries: row['invoice_series'] as String,
      triggerId: row['trigger_id'] as String,
      correlationId: row['correlation_id'] as String,
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
        throw RpcException('Unknown invoice document status: $raw');
    }
  }

  static InvoiceDocumentType mapDocumentType(String raw) {
    switch (raw.toUpperCase()) {
      case 'PDF':
        return InvoiceDocumentType.pdf;
      case 'XML':
        return InvoiceDocumentType.xml;
      default:
        throw RpcException('Unknown invoice document type: $raw');
    }
  }

  static String? failureSourceToRpc(FailureSource? source) => switch (source) {
    FailureSource.provider => 'PROVIDER',
    FailureSource.internal => 'INTERNAL',
    null => null,
  };

  static String documentTypeToRpc(InvoiceDocumentType type) {
    return switch (type) {
      InvoiceDocumentType.pdf => 'PDF',
      InvoiceDocumentType.xml => 'XML',
    };
  }

  static String _documentStatusToRpc(InvoiceDocumentStatus status) {
    switch (status) {
      case InvoiceDocumentStatus.pending:
        return 'PENDING';
      case InvoiceDocumentStatus.available:
        return 'AVAILABLE';
      case InvoiceDocumentStatus.failed:
        return 'FAILED';
      case InvoiceDocumentStatus.checkRequired:
        return 'CHECK_REQUIRED';
    }
  }

  static Map<String, dynamic> recordProviderObservationParams(
    ProviderObservationRecord record,
  ) {
    return {
      'p_tenant_id': record.tenantId,
      'p_electronic_invoice_id': record.electronicInvoiceId,
      'p_provider_state_code': record.providerStateCode,
      'p_provider_state_description': record.safeDescription,
      'p_provider_reference': record.providerReference,
      'p_observed_at': record.observedAt.toUtc().toIso8601String(),
      'p_deduplication_key': record.deduplicationKey,
      'p_details_snapshot': record.detailsSnapshot,
      'p_correlation_id': record.correlationId,
    };
  }

  static ProviderObservationDto observationFromRow(
    Map<String, dynamic> row, {
    String? source,
  }) {
    final correlationId = row['correlation_id'] as String?;
    if (correlationId == null || correlationId.trim().isEmpty) {
      throw RpcException(
        'Provider observation row missing correlation_id',
      );
    }
    return ProviderObservationDto(
      observationId: row['observation_id'] as String,
      electronicInvoiceId: row['electronic_invoice_id'] as String,
      providerStateCode: row['provider_state_code'] as String,
      observedAt: _parseDateTime(row['observed_at'])!,
      safeDescription: row['provider_state_description'] as String?,
      providerReference: row['provider_reference'] as String?,
      source: source,
      correlationId: correlationId,
      detailsSnapshot: Map<String, Object?>.from(
        row['details_snapshot'] as Map? ?? const {},
      ),
    );
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
