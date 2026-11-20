import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/einvoice/data/einvoice_errors.dart';
import 'package:erp/features/einvoice/data/einvoice_processor_trigger.dart';
import 'package:erp/features/einvoice/data/invoice_document_signed_urls.dart';
import 'package:erp/features/einvoice/data/mappers/delivery_json.dart';
import 'package:erp/features/einvoice/data/mappers/electronic_invoice_json.dart';
import 'package:erp/features/einvoice/data/mappers/issuance_json.dart';
import 'package:erp/features/einvoice/data/models.dart';
import 'package:erp/features/einvoice/logic/einvoice_rules.dart';
import 'package:erp/features/einvoice/logic/issuance_readiness_evaluator.dart';

class EInvoiceRepository {
  EInvoiceRepository({
    required SupabaseRpc rpc,
    required EInvoiceProcessorTrigger trigger,
    required InvoiceDocumentSignedUrls signedUrls,
    required Future<String> Function() tenantId,
    required Future<String> Function() actorId,
  })  : _rpc = rpc,
        _trigger = trigger,
        _signedUrls = signedUrls,
        _tenantId = tenantId,
        _actorId = actorId;

  final SupabaseRpc _rpc;
  final EInvoiceProcessorTrigger _trigger;
  final InvoiceDocumentSignedUrls _signedUrls;
  final Future<String> Function() _tenantId;
  final Future<String> Function() _actorId;

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on Object catch (e) {
      throw einvoiceException(e);
    }
  }

  Future<OrderInvoiceProjectionDto> getProjection(String salesOrderId) {
    return _guard(() async {
      final tenant = await _tenantId();
      final actor = await _actorId();
      final rows = await _rpc.rows(
        'einvoice',
        'get_order_invoice_projection',
        params: {
          'p_tenant_id': tenant,
          'p_actor_id': actor,
          'p_sales_order_id': salesOrderId,
        },
      );
      if (rows.isEmpty) {
        throw const AppException(
          EInvoiceErrorCodes.systemError,
          serverMessage: 'get_order_invoice_projection returned no rows',
        );
      }
      return EInvoiceIssuanceJson.orderInvoiceProjectionFromRow(rows.first);
    });
  }

  Future<IssuanceReadinessDto> getReadiness(String salesOrderId) {
    return _guard(() async {
      final tenant = await _tenantId();
      final actor = await _actorId();
      final rows = await _rpc.rows(
        'einvoice',
        'get_issuance_readiness',
        params: {
          'p_tenant_id': tenant,
          'p_actor_id': actor,
          'p_sales_order_id': salesOrderId,
        },
      );
      if (rows.isEmpty) {
        throw const AppException(
          EInvoiceErrorCodes.systemError,
          serverMessage: 'get_issuance_readiness returned no rows',
        );
      }
      final input = EInvoiceIssuanceJson.issuanceReadinessInputFromRow(rows.first);
      final evaluation = IssuanceReadinessEvaluator.evaluate(input);

      return IssuanceReadinessDto(
        level: evaluation.level,
        blockers: evaluation.blockers
            .map((b) => ReadinessBlockerDto(code: b.code, message: b.message))
            .toList(growable: false),
        warnings: evaluation.warnings
            .map((w) => ReadinessWarningDto(code: w.code, message: w.message))
            .toList(growable: false),
        buyerCompletionState: evaluation.buyerCompletionState,
      );
    });
  }

  Future<IssuanceAttemptStatusDto> getAttemptStatus(String salesOrderId) {
    return _guard(() async {
      final tenant = await _tenantId();
      final actor = await _actorId();
      final rows = await _rpc.rows(
        'einvoice',
        'get_issuance_attempt_status',
        params: {
          'p_tenant_id': tenant,
          'p_actor_id': actor,
          'p_sales_order_id': salesOrderId,
        },
      );
      if (rows.isEmpty) {
        throw const AppException(
          EInvoiceErrorCodes.systemError,
          serverMessage: 'get_issuance_attempt_status returned no rows',
        );
      }
      return EInvoiceIssuanceJson.issuanceAttemptStatusFromRow(rows.first);
    });
  }

  Future<InvoicePreviewResultDto> requestPreview({
    required String salesOrderId,
    required int expectedOrderVersion,
  }) {
    return _guard(() async {
      EInvoiceRules.checkSalesOrderId(salesOrderId);
      final tenant = await _tenantId();
      final actor = await _actorId();

      final readinessRows = await _rpc.rows(
        'einvoice',
        'get_issuance_readiness',
        params: {
          'p_tenant_id': tenant,
          'p_actor_id': actor,
          'p_sales_order_id': salesOrderId,
        },
      );
      if (readinessRows.isEmpty) {
        throw const AppException(
          EInvoiceErrorCodes.systemError,
          serverMessage: 'get_issuance_readiness returned no rows',
        );
      }
      final input = EInvoiceIssuanceJson.issuanceReadinessInputFromRow(readinessRows.first);
      final evaluation = IssuanceReadinessEvaluator.evaluate(input);

      if (!evaluation.canPreview) {
        final hasConfigNotReady = evaluation.blockers.any(
          (b) => b.code == EInvoiceErrorCodes.configNotReady,
        );
        if (hasConfigNotReady) {
          throw const AppException(EInvoiceErrorCodes.configNotReady);
        }
        throw AppException(
          EInvoiceErrorCodes.issuanceNotReady,
          serverMessage: 'Không đủ điều kiện xem trước',
          details: {
            'blockers': evaluation.blockers.map((b) => b.code).toList(growable: false),
          },
        );
      }

      final previewRows = await _rpc.rows(
        'einvoice',
        'request_invoice_preview',
        params: {
          'p_tenant_id': tenant,
          'p_actor_id': actor,
          'p_sales_order_id': salesOrderId,
          'p_expected_order_version': expectedOrderVersion,
        },
      );
      if (previewRows.isEmpty) {
        throw const AppException(
          EInvoiceErrorCodes.systemError,
          serverMessage: 'request_invoice_preview returned no rows',
        );
      }

      _trigger.kick(tenant);
      return InvoicePreviewResultDto(
        viewerRef: null,
        warnings: evaluation.warnings.map((w) => w.message).toList(growable: false),
      );
    });
  }

  Future<InvoicePreviewResultDto> getPreview(String salesOrderId) {
    return _guard(() async {
      final tenant = await _tenantId();
      final actor = await _actorId();
      final rows = await _rpc.rows(
        'einvoice',
        'get_invoice_preview',
        params: {
          'p_tenant_id': tenant,
          'p_actor_id': actor,
          'p_sales_order_id': salesOrderId,
        },
      );
      if (rows.isEmpty) {
        return const InvoicePreviewResultDto(viewerRef: null, warnings: []);
      }
      return EInvoiceIssuanceJson.invoicePreviewResultFromRow(rows.first);
    });
  }

  Future<IssueInvoiceResultDto> issue({
    required String salesOrderId,
    required String sourceVersion,
    required String idempotencyKey,
    bool? acknowledgeWarnings,
  }) {
    return _guard(() async {
      EInvoiceRules.checkIssue(
        salesOrderId: salesOrderId,
        sourceVersion: sourceVersion,
        idempotencyKey: idempotencyKey,
      );
      final tenant = await _tenantId();
      final actor = await _actorId();
      final params = <String, dynamic>{
        'p_tenant_id': tenant,
        'p_actor_id': actor,
        'p_sales_order_id': salesOrderId,
        'p_source_version': sourceVersion,
        'p_idempotency_key': idempotencyKey,
        'p_acknowledge_warnings': acknowledgeWarnings ?? false,
      };
      final rows = await _rpc.rows('einvoice', 'issue_invoice', params: params);
      if (rows.isEmpty) {
        throw const AppException(
          EInvoiceErrorCodes.systemError,
          serverMessage: 'issue_invoice returned no rows',
        );
      }
      final result = EInvoiceIssuanceJson.issueInvoiceResultFromRow(rows.first);
      _trigger.kick(tenant);
      return result;
    });
  }

  Future<IssueInvoiceResultDto> retry({
    required String salesOrderId,
    required int expectedOrderVersion,
    required String idempotencyKey,
    bool? acknowledgeWarnings,
  }) {
    return _guard(() async {
      EInvoiceRules.checkRetry(
        salesOrderId: salesOrderId,
        expectedOrderVersion: expectedOrderVersion,
        idempotencyKey: idempotencyKey,
      );
      final tenant = await _tenantId();
      final actor = await _actorId();
      final params = <String, dynamic>{
        'p_tenant_id': tenant,
        'p_actor_id': actor,
        'p_sales_order_id': salesOrderId,
        'p_expected_order_version': expectedOrderVersion.toString(),
        'p_idempotency_key': idempotencyKey,
        'p_acknowledge_warnings': acknowledgeWarnings ?? false,
      };
      final rows = await _rpc.rows('einvoice', 'retry_issuance', params: params);
      if (rows.isEmpty) {
        throw const AppException(
          EInvoiceErrorCodes.systemError,
          serverMessage: 'retry_issuance returned no rows',
        );
      }
      final result = EInvoiceIssuanceJson.issueInvoiceResultFromRow(rows.first);
      _trigger.kick(tenant);
      return result;
    });
  }

  Future<OfficialInvoiceViewDto> requestOfficialView(String salesOrderId) {
    return _guard(() async {
      EInvoiceRules.checkSalesOrderId(salesOrderId);
      final tenant = await _tenantId();
      final actor = await _actorId();
      final rows = await _rpc.rows(
        'einvoice',
        'request_official_invoice_view',
        params: {
          'p_tenant_id': tenant,
          'p_actor_id': actor,
          'p_sales_order_id': salesOrderId,
        },
      );
      if (rows.isEmpty) {
        throw const AppException(
          EInvoiceErrorCodes.systemError,
          serverMessage: 'request_official_invoice_view returned no rows',
        );
      }
      final result = EInvoiceDocumentJson.officialViewFromRow(rows.first);
      _trigger.kick(tenant);
      return result;
    });
  }

  Future<ElectronicInvoiceDetailDto> getDetail(String salesOrderId) {
    return _guard(() async {
      final tenant = await _tenantId();
      final actor = await _actorId();
      final rows = await _rpc.rows(
        'einvoice',
        'get_electronic_invoice_detail',
        params: {
          'p_tenant_id': tenant,
          'p_actor_id': actor,
          'p_sales_order_id': salesOrderId,
        },
      );
      if (rows.isEmpty) {
        throw const AppException(
          EInvoiceErrorCodes.systemError,
          serverMessage: 'get_electronic_invoice_detail returned no rows',
        );
      }
      return EInvoiceDocumentJson.detailFromRow(rows.first);
    });
  }

  Future<InvoiceDocumentRetrievalDto> requestDocument({
    required String salesOrderId,
    required InvoiceDocumentType documentType,
  }) {
    return _guard(() async {
      EInvoiceRules.checkSalesOrderId(salesOrderId);
      final tenant = await _tenantId();
      final actor = await _actorId();
      final rows = await _rpc.rows(
        'einvoice',
        'request_invoice_document',
        params: {
          'p_tenant_id': tenant,
          'p_actor_id': actor,
          'p_sales_order_id': salesOrderId,
          'p_document_type': EInvoiceDocumentJson.documentTypeToRpc(documentType),
        },
      );
      if (rows.isEmpty) {
        throw const AppException(
          EInvoiceErrorCodes.systemError,
          serverMessage: 'request_invoice_document returned no rows',
        );
      }
      final dto = EInvoiceDocumentJson.documentRetrievalFromRow(rows.first);
      final signed = await _withSignedDownloadUrl(dto);
      _trigger.kick(tenant);
      return signed;
    });
  }

  Future<InvoiceDocumentsDto> getDocuments(String salesOrderId) {
    return _guard(() async {
      final tenant = await _tenantId();
      final actor = await _actorId();
      final rows = await _rpc.rows(
        'einvoice',
        'get_invoice_documents',
        params: {
          'p_tenant_id': tenant,
          'p_actor_id': actor,
          'p_sales_order_id': salesOrderId,
        },
      );
      if (rows.isEmpty) {
        throw const AppException(
          EInvoiceErrorCodes.systemError,
          serverMessage: 'get_invoice_documents returned no rows',
        );
      }
      final dto = EInvoiceDocumentJson.documentsFromRow(rows.first);
      return _withSignedDownloadUrls(dto);
    });
  }

  Future<SendInvoiceSheetContextDto> getSendSheetContext(String salesOrderId) {
    return _guard(() async {
      final tenant = await _tenantId();
      final actor = await _actorId();
      final rows = await _rpc.rows(
        'einvoice',
        'get_send_invoice_sheet_context',
        params: {
          'p_tenant_id': tenant,
          'p_actor_id': actor,
          'p_sales_order_id': salesOrderId,
        },
      );
      if (rows.isEmpty) {
        throw const AppException(
          EInvoiceErrorCodes.systemError,
          serverMessage: 'get_send_invoice_sheet_context returned no rows',
        );
      }
      return EInvoiceDeliveryJson.sendSheetContextFromRow(rows.first);
    });
  }

  Future<SendInvoiceResultDto> send({
    required String salesOrderId,
    required String recipientEmail,
    required String idempotencyKey,
  }) {
    return _guard(() async {
      EInvoiceRules.checkSend(
        salesOrderId: salesOrderId,
        recipientEmail: recipientEmail,
        idempotencyKey: idempotencyKey,
      );
      final tenant = await _tenantId();
      final actor = await _actorId();
      final params = <String, dynamic>{
        'p_tenant_id': tenant,
        'p_actor_id': actor,
        'p_sales_order_id': salesOrderId,
        'p_recipient_email': recipientEmail,
        'p_idempotency_key': idempotencyKey,
      };
      final rows = await _rpc.rows('einvoice', 'send_electronic_invoice', params: params);
      if (rows.isEmpty) {
        throw const AppException(
          EInvoiceErrorCodes.systemError,
          serverMessage: 'send_electronic_invoice returned no rows',
        );
      }
      final result = EInvoiceDeliveryJson.sendInvoiceResultFromRow(rows.first);
      _trigger.kick(tenant);
      return result;
    });
  }

  Future<InvoiceDeliveryHistoryDto> getDeliveryHistory(String salesOrderId) {
    return _guard(() async {
      final tenant = await _tenantId();
      final actor = await _actorId();
      final rows = await _rpc.rows(
        'einvoice',
        'get_invoice_delivery_history',
        params: {
          'p_tenant_id': tenant,
          'p_actor_id': actor,
          'p_sales_order_id': salesOrderId,
        },
      );
      if (rows.isEmpty) {
        throw const AppException(
          EInvoiceErrorCodes.systemError,
          serverMessage: 'get_invoice_delivery_history returned no rows',
        );
      }
      return EInvoiceDeliveryJson.historyFromRow(rows.first);
    });
  }

  // --- Private signed URL helpers ---

  Future<InvoiceDocumentRetrievalDto> _withSignedDownloadUrl(
    InvoiceDocumentRetrievalDto dto,
  ) async {
    if (dto.status != InvoiceDocumentStatus.available ||
        dto.fileRef == null ||
        dto.fileRef!.isEmpty) {
      return dto;
    }

    final downloadUrl = await _signedUrls.tryCreate(dto.fileRef!);
    if (downloadUrl == null) {
      return InvoiceDocumentRetrievalDto(
        operationId: dto.operationId,
        status: InvoiceDocumentStatus.checkRequired,
        fileRef: dto.fileRef,
        checksum: dto.checksum,
      );
    }

    return InvoiceDocumentRetrievalDto(
      operationId: dto.operationId,
      status: dto.status,
      downloadUrl: downloadUrl,
      fileRef: dto.fileRef,
      checksum: dto.checksum,
    );
  }

  Future<InvoiceDocumentsDto> _withSignedDownloadUrls(
    InvoiceDocumentsDto dto,
  ) async {
    final pdf = await _withSignedItem(dto.pdf);
    final xml = await _withSignedItem(dto.xml);
    final retrievalStatus = _aggregateRetrievalStatus(
      dto.retrievalStatus,
      pdf?.status,
      xml?.status,
    );
    return InvoiceDocumentsDto(
      pdfAvailable: dto.pdfAvailable,
      xmlAvailable: dto.xmlAvailable,
      retrievalStatus: retrievalStatus,
      pdf: pdf,
      xml: xml,
    );
  }

  Future<InvoiceDocumentItemDto?> _withSignedItem(
    InvoiceDocumentItemDto? item,
  ) async {
    if (item == null) {
      return null;
    }
    if (item.status != InvoiceDocumentStatus.available ||
        item.fileRef == null ||
        item.fileRef!.isEmpty) {
      return item;
    }

    final downloadUrl = await _signedUrls.tryCreate(item.fileRef!);
    if (downloadUrl == null) {
      return InvoiceDocumentItemDto(
        documentType: item.documentType,
        status: InvoiceDocumentStatus.checkRequired,
        operationId: item.operationId,
        fileRef: item.fileRef,
        checksum: item.checksum,
        failureCode: item.failureCode,
      );
    }

    return InvoiceDocumentItemDto(
      documentType: item.documentType,
      status: item.status,
      operationId: item.operationId,
      downloadUrl: downloadUrl,
      fileRef: item.fileRef,
      checksum: item.checksum,
      expiresAt: _signedUrls.leaseExpiresAt(),
      failureCode: item.failureCode,
    );
  }

  InvoiceDocumentStatus _aggregateRetrievalStatus(
    InvoiceDocumentStatus base,
    InvoiceDocumentStatus? pdfStatus,
    InvoiceDocumentStatus? xmlStatus,
  ) {
    final statuses = [
      base,
      pdfStatus,
      xmlStatus,
    ].whereType<InvoiceDocumentStatus>();
    if (statuses.any(
      (status) => status == InvoiceDocumentStatus.checkRequired,
    )) {
      return InvoiceDocumentStatus.checkRequired;
    }
    if (statuses.any((status) => status == InvoiceDocumentStatus.pending)) {
      return InvoiceDocumentStatus.pending;
    }
    if (statuses.any((status) => status == InvoiceDocumentStatus.available)) {
      return InvoiceDocumentStatus.available;
    }
    if (statuses.any((status) => status == InvoiceDocumentStatus.failed)) {
      return InvoiceDocumentStatus.failed;
    }
    return base;
  }
}
