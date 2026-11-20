import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/einvoice/data/einvoice_errors.dart';
import 'package:erp/features/einvoice/data/einvoice_processor_trigger.dart';
import 'package:erp/features/einvoice/data/einvoice_repository.dart';
import 'package:erp/features/einvoice/data/invoice_document_signed_urls.dart';
import 'package:erp/features/einvoice/data/models.dart';
import 'package:supabase/supabase.dart';
import 'fake_einvoice_scenario.dart';

export 'fake_einvoice_scenario.dart';

class _DummyRpc implements SupabaseRpc {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummyFunctions implements FunctionsClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #invoke) {
      return Future.value(FunctionResponse(status: 200, data: null));
    }
    return super.noSuchMethod(invocation);
  }
}

class _DummyStorage implements SupabaseStorageClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeEInvoiceRepository extends EInvoiceRepository {
  FakeEInvoiceRepository({
    OrderInvoiceProjectionDto? projection,
    this.readiness = const IssuanceReadinessDto(
      level: IssuanceReadinessLevel.ready,
      blockers: [],
      warnings: [],
      buyerCompletionState: BuyerCompletionStatus.open,
    ),
    this.attemptStatus = const IssuanceAttemptStatusDto(
      attemptId: 'att-1',
      status: IssuanceAttemptStatus.submitted,
      internalFinalizationStatus: InternalFinalizationStatus.pending,
      hasElectronicInvoice: false,
      hasActiveOperation: false,
    ),
    List<InvoicePreviewResultDto>? previewResults,
    List<ElectronicInvoiceDetailDto>? detailResults,
    List<InvoiceDocumentsDto>? documentResults,
    this.requestPreviewResult = const InvoicePreviewResultDto(
      viewerRef: 'https://preview.fake/invoice-1',
      warnings: [],
    ),
    this.officialViewResult = const OfficialInvoiceViewDto(
      viewerUrl: 'https://view.fake/invoice',
      status: InvoiceDocumentStatus.available,
    ),
    this.documentResult = const InvoiceDocumentRetrievalDto(
      downloadUrl: 'https://download.fake/invoice.pdf',
      status: InvoiceDocumentStatus.available,
      checksum: 'sha256-fake',
    ),
    this.issueResult = const IssueInvoiceResultDto(
      issuanceId: 'iss-1',
      attemptId: 'att-1',
      status: IssuanceAttemptStatus.submitted,
    ),
    this.sendContext = const SendInvoiceSheetContextDto(
      mode: SendInvoiceSheetMode.send,
      suggestedEmail: 'buyer@fake.test',
      suggestedEmailSource: DeliveryRecipientSource.currentPartnerProfile,
      history: [],
      operationLocked: false,
      displayState: DeliveryDisplayState.notSent,
    ),
    this.sendResult = const SendInvoiceResultDto(
      deliveryId: 'del-1',
      status: DeliveryStatus.processing,
    ),
    this.history = const InvoiceDeliveryHistoryDto(
      deliveries: [],
      displayState: DeliveryDisplayState.notSent,
      hasSecondaryAttention: false,
    ),
    Map<String, Object>? throwOn,
    Map<String, Completer<void>>? holdOn,
  })  : calls = <String>[],
        projection = projection ??
            const OrderInvoiceProjectionDto(
              salesOrderId: 'order-1',
              issuanceDisplayState: IssuanceDisplayState.processing,
              actions: [OrderInvoiceAction.issue],
            ),
        previewResults = previewResults ?? <InvoicePreviewResultDto>[],
        detailResults = detailResults ?? <ElectronicInvoiceDetailDto>[],
        documentResults = documentResults ?? <InvoiceDocumentsDto>[],
        throwOn = throwOn ?? <String, Object>{},
        holdOn = holdOn ?? <String, Completer<void>>{},
        super(
          rpc: _DummyRpc(),
          trigger: EInvoiceProcessorTrigger(_DummyFunctions()),
          signedUrls: InvoiceDocumentSignedUrls(storage: _DummyStorage()),
          tenantId: () async => 'tenant-1',
          actorId: () async => 'actor-1',
        );

  final List<String> calls;
  final List<({String salesOrderId, String recipientEmail, String idempotencyKey})> sendCalls = [];

  factory FakeEInvoiceRepository.forScenario(FakeEInvoiceScenario scenario) {
    final repo = FakeEInvoiceRepository();
    switch (scenario) {
      case FakeEInvoiceScenario.previewConfigNotReady:
        repo.throwOn['requestPreview'] = const AppException(EInvoiceErrorCodes.configNotReady);
        repo.throwOn['getPreview'] = const AppException(EInvoiceErrorCodes.configNotReady);
        break;
      case FakeEInvoiceScenario.previewProviderUnavailable:
        repo.throwOn['requestPreview'] = const AppException(EInvoiceErrorCodes.providerUnavailable);
        break;
      case FakeEInvoiceScenario.previewPermissionDenied:
        repo.throwOn['requestPreview'] = const AppException(EInvoiceErrorCodes.noPermission);
        break;
      case FakeEInvoiceScenario.configReadinessBlocked:
        repo.readiness = const IssuanceReadinessDto(
          level: IssuanceReadinessLevel.notReady,
          blockers: [
            ReadinessBlockerDto(
              code: EInvoiceErrorCodes.providerNotConnected,
              message: 'Provider not connected',
            ),
          ],
          warnings: [],
          buyerCompletionState: BuyerCompletionStatus.open,
        );
        break;
      case FakeEInvoiceScenario.readinessBuyerIncomplete:
        repo.readiness = const IssuanceReadinessDto(
          level: IssuanceReadinessLevel.notReady,
          blockers: [
            ReadinessBlockerDto(
              code: EInvoiceErrorCodes.buyerDataIncomplete,
              message: 'Missing buyer email',
            ),
          ],
          warnings: [],
          buyerCompletionState: BuyerCompletionStatus.open,
        );
        break;
      case FakeEInvoiceScenario.retryWhileReconciling:
        repo.throwOn['retry'] = const AppException(EInvoiceErrorCodes.stateChanged);
        break;
      case FakeEInvoiceScenario.officialViewProviderDown:
        repo.projection = const OrderInvoiceProjectionDto(
          salesOrderId: 'so-fake-001',
          issuanceDisplayState: IssuanceDisplayState.issued,
          actions: [OrderInvoiceAction.view],
        );
        repo.throwOn['requestOfficialView'] = const AppException(EInvoiceErrorCodes.providerUnavailable);
        break;
      case FakeEInvoiceScenario.downloadUnavailable:
        repo.projection = const OrderInvoiceProjectionDto(
          salesOrderId: 'so-fake-001',
          issuanceDisplayState: IssuanceDisplayState.issued,
          actions: [
            OrderInvoiceAction.view,
            OrderInvoiceAction.downloadPdf,
            OrderInvoiceAction.downloadXml,
          ],
        );
        repo.documentResult = const InvoiceDocumentRetrievalDto(
          operationId: 'op-doc-failed-1',
          status: InvoiceDocumentStatus.failed,
        );
        break;
      case FakeEInvoiceScenario.downloadPdfOk:
        repo.projection = const OrderInvoiceProjectionDto(
          salesOrderId: 'so-fake-001',
          issuanceDisplayState: IssuanceDisplayState.issued,
          actions: [
            OrderInvoiceAction.view,
            OrderInvoiceAction.downloadPdf,
            OrderInvoiceAction.downloadXml,
          ],
        );
        repo.documentResult = const InvoiceDocumentRetrievalDto(
          operationId: 'op-doc-pdf-1',
          status: InvoiceDocumentStatus.pending,
        );
        repo.documentResults = [
          const InvoiceDocumentsDto(
            pdfAvailable: true,
            xmlAvailable: false,
            retrievalStatus: InvoiceDocumentStatus.available,
            pdf: InvoiceDocumentItemDto(
              documentType: InvoiceDocumentType.pdf,
              status: InvoiceDocumentStatus.available,
              operationId: 'op-doc-pdf-1',
              downloadUrl: 'https://download.fake/signed/pdf',
              fileRef: 'einvoice-documents/fake/invoice.pdf',
              checksum: 'pdf-checksum-1',
            ),
          ),
        ];
        break;
      case FakeEInvoiceScenario.sendSheetInitial:
        repo.projection = const OrderInvoiceProjectionDto(
          salesOrderId: 'so-fake-001',
          issuanceDisplayState: IssuanceDisplayState.issued,
          deliveryDisplayState: DeliveryDisplayState.notSent,
          actions: [
            OrderInvoiceAction.view,
            OrderInvoiceAction.send,
          ],
        );
        repo.sendContext = const SendInvoiceSheetContextDto(
          mode: SendInvoiceSheetMode.send,
          suggestedEmail: 'buyer@fake.test',
          suggestedEmailSource: DeliveryRecipientSource.currentPartnerProfile,
          history: [],
          operationLocked: false,
          displayState: DeliveryDisplayState.notSent,
        );
        break;
      case FakeEInvoiceScenario.sendSheetResend:
        repo.projection = const OrderInvoiceProjectionDto(
          salesOrderId: 'so-fake-001',
          issuanceDisplayState: IssuanceDisplayState.issued,
          deliveryDisplayState: DeliveryDisplayState.sent,
          actions: [
            OrderInvoiceAction.view,
            OrderInvoiceAction.send,
          ],
        );
        repo.sendContext = SendInvoiceSheetContextDto(
          mode: SendInvoiceSheetMode.resend,
          suggestedEmail: 'buyer@fake.test',
          suggestedEmailSource: DeliveryRecipientSource.lastInvoiceDelivery,
          history: [
            InvoiceDeliveryItemDto(
              deliveryId: 'del-1',
              deliveryNo: 1,
              kind: DeliveryKind.initial,
              triggerType: DeliveryTriggerType.automatic,
              recipientEmail: 'buyer@fake.test',
              status: DeliveryStatus.succeeded,
              initiatedByActorType: DeliveryActorType.system,
              initiatedByActorId: null,
              startedAt: DateTime.utc(2026, 1, 1),
              completedAt: DateTime.utc(2026, 1, 1),
              failureCode: null,
            ),
          ],
          operationLocked: false,
          displayState: DeliveryDisplayState.sent,
        );
        break;
      case FakeEInvoiceScenario.sendInvalidEmail:
        repo.projection = const OrderInvoiceProjectionDto(
          salesOrderId: 'so-fake-001',
          issuanceDisplayState: IssuanceDisplayState.issued,
          actions: [
            OrderInvoiceAction.view,
            OrderInvoiceAction.send,
          ],
        );
        repo.throwOn['send'] = const AppException(
          EInvoiceErrorCodes.systemError,
          serverMessage: 'Invalid email format',
        );
        break;
      case FakeEInvoiceScenario.sendSheetUnknown:
        repo.projection = const OrderInvoiceProjectionDto(
          salesOrderId: 'so-fake-001',
          issuanceDisplayState: IssuanceDisplayState.issued,
          deliveryDisplayState: DeliveryDisplayState.unknown,
          actions: [
            OrderInvoiceAction.view,
            OrderInvoiceAction.send,
          ],
        );
        repo.sendContext = SendInvoiceSheetContextDto(
          mode: SendInvoiceSheetMode.resend,
          suggestedEmail: 'buyer@fake.test',
          suggestedEmailSource: DeliveryRecipientSource.lastInvoiceDelivery,
          history: [
            InvoiceDeliveryItemDto(
              deliveryId: 'del-1',
              deliveryNo: 1,
              kind: DeliveryKind.initial,
              triggerType: DeliveryTriggerType.automatic,
              recipientEmail: 'buyer@fake.test',
              status: DeliveryStatus.unknown,
              initiatedByActorType: DeliveryActorType.system,
              initiatedByActorId: null,
              startedAt: DateTime.utc(2026, 1, 1),
              completedAt: null,
              failureCode: null,
            ),
          ],
          operationLocked: false,
          displayState: DeliveryDisplayState.unknown,
        );
        break;
      default:
        break;
    }
    return repo;
  }
  OrderInvoiceProjectionDto projection;
  IssuanceReadinessDto? readiness;
  IssuanceAttemptStatusDto? attemptStatus;
  List<InvoicePreviewResultDto> previewResults;
  List<ElectronicInvoiceDetailDto> detailResults;
  List<InvoiceDocumentsDto> documentResults;
  InvoicePreviewResultDto requestPreviewResult;
  OfficialInvoiceViewDto officialViewResult;
  InvoiceDocumentRetrievalDto documentResult;
  IssueInvoiceResultDto issueResult;
  SendInvoiceSheetContextDto? sendContext;
  SendInvoiceResultDto sendResult;
  InvoiceDeliveryHistoryDto history;
  final Map<String, Object> throwOn;
  final Map<String, Completer<void>> holdOn;

  int _previewIndex = 0;
  int _detailIndex = 0;
  int _documentIndex = 0;

  Future<void> _record(String name) async {
    calls.add(name);
    final hold = holdOn[name];
    if (hold != null) {
      await hold.future;
    }
    final error = throwOn[name];
    if (error != null) {
      throw error;
    }
  }

  InvoicePreviewResultDto _nextPreview() {
    if (previewResults.isEmpty) return requestPreviewResult;
    final res = previewResults[_previewIndex.clamp(0, previewResults.length - 1)];
    if (_previewIndex < previewResults.length - 1) {
      _previewIndex++;
    }
    return res;
  }

  ElectronicInvoiceDetailDto _nextDetail() {
    if (detailResults.isEmpty) {
      return const ElectronicInvoiceDetailDto(
        electronicInvoiceId: 'inv-1',
        salesOrderId: 'order-1',
      );
    }
    final res = detailResults[_detailIndex.clamp(0, detailResults.length - 1)];
    if (_detailIndex < detailResults.length - 1) {
      _detailIndex++;
    }
    return res;
  }

  InvoiceDocumentsDto _nextDocument() {
    if (documentResults.isEmpty) {
      return const InvoiceDocumentsDto(
        pdfAvailable: false,
        xmlAvailable: false,
        retrievalStatus: InvoiceDocumentStatus.available,
      );
    }
    final res = documentResults[_documentIndex.clamp(0, documentResults.length - 1)];
    if (_documentIndex < documentResults.length - 1) {
      _documentIndex++;
    }
    return res;
  }

  @override
  Future<OrderInvoiceProjectionDto> getProjection(String salesOrderId) async {
    await _record('getProjection');
    return projection;
  }

  @override
  Future<IssuanceReadinessDto> getReadiness(String salesOrderId) async {
    await _record('getReadiness');
    if (readiness == null) {
      throw const AppException(EInvoiceErrorCodes.systemError);
    }
    return readiness!;
  }

  @override
  Future<IssuanceAttemptStatusDto> getAttemptStatus(String salesOrderId) async {
    await _record('getAttemptStatus');
    if (attemptStatus == null) {
      throw const AppException(EInvoiceErrorCodes.notFound);
    }
    return attemptStatus!;
  }

  @override
  Future<InvoicePreviewResultDto> requestPreview({
    required String salesOrderId,
    required int expectedOrderVersion,
  }) async {
    await _record('requestPreview');
    return requestPreviewResult;
  }

  @override
  Future<InvoicePreviewResultDto> getPreview(String salesOrderId) async {
    await _record('getPreview');
    return _nextPreview();
  }

  @override
  Future<IssueInvoiceResultDto> issue({
    required String salesOrderId,
    required String sourceVersion,
    required String idempotencyKey,
    bool? acknowledgeWarnings,
  }) async {
    await _record('issue');
    projection = OrderInvoiceProjectionDto(
      salesOrderId: salesOrderId,
      issuanceDisplayState: IssuanceDisplayState.processing,
      deliveryDisplayState: projection.deliveryDisplayState,
      deliveryPending: projection.deliveryPending,
      hasSecondaryAttention: projection.hasSecondaryAttention,
      actions: const [],
    );
    return issueResult;
  }

  @override
  Future<IssueInvoiceResultDto> retry({
    required String salesOrderId,
    required int expectedOrderVersion,
    required String idempotencyKey,
    bool? acknowledgeWarnings,
  }) async {
    await _record('retry');
    projection = OrderInvoiceProjectionDto(
      salesOrderId: salesOrderId,
      issuanceDisplayState: IssuanceDisplayState.processing,
      deliveryDisplayState: projection.deliveryDisplayState,
      deliveryPending: projection.deliveryPending,
      hasSecondaryAttention: projection.hasSecondaryAttention,
      actions: const [],
    );
    return issueResult;
  }

  @override
  Future<OfficialInvoiceViewDto> requestOfficialView(String salesOrderId) async {
    await _record('requestOfficialView');
    return officialViewResult;
  }

  @override
  Future<ElectronicInvoiceDetailDto> getDetail(String salesOrderId) async {
    await _record('getDetail');
    return _nextDetail();
  }

  @override
  Future<InvoiceDocumentRetrievalDto> requestDocument({
    required String salesOrderId,
    required InvoiceDocumentType documentType,
  }) async {
    await _record('requestDocument');
    return documentResult;
  }

  @override
  Future<InvoiceDocumentsDto> getDocuments(String salesOrderId) async {
    await _record('getDocuments');
    return _nextDocument();
  }

  @override
  Future<SendInvoiceSheetContextDto> getSendSheetContext(String salesOrderId) async {
    await _record('getSendSheetContext');
    if (sendContext == null) {
      throw const AppException(EInvoiceErrorCodes.systemError);
    }
    return sendContext!;
  }

  @override
  Future<SendInvoiceResultDto> send({
    required String salesOrderId,
    required String recipientEmail,
    required String idempotencyKey,
  }) async {
    sendCalls.add((
      salesOrderId: salesOrderId,
      recipientEmail: recipientEmail,
      idempotencyKey: idempotencyKey,
    ));
    await _record('send');
    return sendResult;
  }

  @override
  Future<InvoiceDeliveryHistoryDto> getDeliveryHistory(String salesOrderId) async {
    await _record('getDeliveryHistory');
    return history;
  }
}
