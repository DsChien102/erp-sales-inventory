import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_application/application.dart';

final class RecordingElectronicInvoiceCommandGateway implements IElectronicInvoiceCommandGateway {
  final List<
    ({
      String tenantId,
      String actorId,
      String salesOrderId,
    })
  >
  officialViewRequests = [];

  final List<
    ({
      String tenantId,
      String actorId,
      String salesOrderId,
      InvoiceDocumentType documentType,
      String idempotencyKey,
    })
  >
  documentRequests = [];

  @override
  Future<OfficialInvoiceViewDto> requestOfficialView({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) async {
    officialViewRequests.add((
      tenantId: tenantId,
      actorId: actorId,
      salesOrderId: salesOrderId,
    ));
    return const OfficialInvoiceViewDto(
      operationId: 'op-official-1',
      status: InvoiceDocumentStatus.pending,
    );
  }

  @override
  Future<InvoiceDocumentRetrievalDto> requestDocument({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
    required InvoiceDocumentType documentType,
    required String idempotencyKey,
  }) async {
    documentRequests.add((
      tenantId: tenantId,
      actorId: actorId,
      salesOrderId: salesOrderId,
      documentType: documentType,
      idempotencyKey: idempotencyKey,
    ));
    return const InvoiceDocumentRetrievalDto(
      operationId: 'op-doc-1',
      status: InvoiceDocumentStatus.pending,
    );
  }

  @override
  Future<OfficialViewOperationContextDto?> loadOfficialViewContext({
    required String tenantId,
    required String operationId,
  }) async => null;

  @override
  Future<InvoiceDocumentOperationContextDto?> loadDocumentContext({
    required String tenantId,
    required String operationId,
  }) async => null;

  @override
  Future<ProviderObservationOperationContextDto?> loadObservationContext({
    required String tenantId,
    required String commandId,
  }) async => null;

  @override
  Future<void> recordOfficialViewResult(OfficialViewResultRecord record) async {}

  @override
  Future<void> recordDocumentResult(InvoiceDocumentResultRecord record) async {}

  final List<ProviderObservationRecord> observationRecords = [];

  @override
  Future<ProviderObservationDto> recordProviderObservation(
    ProviderObservationRecord record,
  ) async {
    observationRecords.add(record);
    return ProviderObservationDto(
      observationId: 'obs-1',
      electronicInvoiceId: record.electronicInvoiceId,
      providerStateCode: record.providerStateCode,
      observedAt: record.observedAt,
      safeDescription: record.safeDescription,
      providerReference: record.providerReference,
      source: record.source,
      correlationId: 'corr-1',
      detailsSnapshot: record.detailsSnapshot,
    );
  }
}

final class RecordingElectronicInvoiceReadGateway implements IElectronicInvoiceReadGateway {
  String? lastTenantId;
  String? lastActorId;
  String? lastSalesOrderId;

  @override
  Future<ElectronicInvoiceDetailDto> getDetail({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) async {
    lastTenantId = tenantId;
    lastActorId = actorId;
    lastSalesOrderId = salesOrderId;
    return ElectronicInvoiceDetailDto(
      electronicInvoiceId: 'ei-1',
      salesOrderId: salesOrderId,
    );
  }

  @override
  Future<InvoiceDocumentsDto> getDocuments({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) async {
    lastTenantId = tenantId;
    lastActorId = actorId;
    lastSalesOrderId = salesOrderId;
    return const InvoiceDocumentsDto(
      pdfAvailable: true,
      xmlAvailable: false,
      retrievalStatus: InvoiceDocumentStatus.pending,
    );
  }

  @override
  Future<ProviderObservationDto?> getLatestObservation({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) async {
    lastTenantId = tenantId;
    lastActorId = actorId;
    lastSalesOrderId = salesOrderId;
    return ProviderObservationDto(
      observationId: 'obs-1',
      electronicInvoiceId: 'ei-1',
      providerStateCode: 'PUBLISHED',
      observedAt: DateTime.utc(2026, 8, 31),
      correlationId: 'corr-1',
    );
  }
}

/// Configurable gateway for S4 worker handler tests.
final class StubOfficialViewCommandGateway extends RecordingElectronicInvoiceCommandGateway {
  OfficialViewOperationContextDto? officialViewContext;
  OfficialViewResultRecord? lastOfficialViewResult;

  @override
  Future<OfficialViewOperationContextDto?> loadOfficialViewContext({
    required String tenantId,
    required String operationId,
  }) async => officialViewContext;

  @override
  Future<void> recordOfficialViewResult(OfficialViewResultRecord record) async {
    lastOfficialViewResult = record;
  }
}

final class StubElectronicInvoiceProviderPort implements IElectronicInvoiceProviderPort {
  OfficialViewProviderOutcome? officialOutcome;
  int fetchOfficialViewCalls = 0;

  @override
  Future<OfficialViewProviderOutcome> fetchOfficialView(
    ElectronicInvoiceProviderContextDto context,
  ) async {
    fetchOfficialViewCalls++;
    return officialOutcome ??
        const OfficialViewProviderAmbiguous(safeErrorCode: 'PROVIDER_TIMEOUT');
  }

  @override
  Future<InvoiceDocumentProviderOutcome> downloadDocument(
    ElectronicInvoiceProviderContextDto context,
    InvoiceDocumentType documentType,
  ) => throw UnimplementedError();

  @override
  Future<ProviderObservationOutcome> observe(
    ElectronicInvoiceProviderContextDto context,
  ) => throw UnimplementedError();
}
