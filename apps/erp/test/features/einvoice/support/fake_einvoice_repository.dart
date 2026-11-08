import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/einvoice/data/einvoice_errors.dart';
import 'package:erp/features/einvoice/data/einvoice_processor_trigger.dart';
import 'package:erp/features/einvoice/data/einvoice_repository.dart';
import 'package:erp/features/einvoice/data/invoice_document_signed_urls.dart';
import 'package:erp/features/einvoice/data/models.dart';
import 'package:supabase/supabase.dart';

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
      viewerUrl: 'https://view.fake/invoice-1',
      status: InvoiceDocumentStatus.available,
    ),
    this.documentResult = const InvoiceDocumentRetrievalDto(
      downloadUrl: 'https://download.fake/invoice-1.pdf',
      status: InvoiceDocumentStatus.available,
    ),
    this.issueResult = const IssueInvoiceResultDto(
      issuanceId: 'iss-1',
      attemptId: 'att-1',
      status: IssuanceAttemptStatus.submitted,
    ),
    this.sendContext = const SendInvoiceSheetContextDto(
      mode: SendInvoiceSheetMode.send,
      suggestedEmail: 'buyer@fake.vn',
      suggestedEmailSource: DeliveryRecipientSource.buyerInvoiceSnapshot,
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
  OrderInvoiceProjectionDto projection;
  IssuanceReadinessDto? readiness;
  IssuanceAttemptStatusDto? attemptStatus;
  final List<InvoicePreviewResultDto> previewResults;
  final List<ElectronicInvoiceDetailDto> detailResults;
  final List<InvoiceDocumentsDto> documentResults;
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
    await _record('send');
    return sendResult;
  }

  @override
  Future<InvoiceDeliveryHistoryDto> getDeliveryHistory(String salesOrderId) async {
    await _record('getDeliveryHistory');
    return history;
  }
}
