import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

abstract final class IssuanceRpcMapper {
  static Map<String, dynamic> issueInvoiceParams(
    IssueInvoiceStartRequest request,
  ) {
    return {
      'p_tenant_id': request.tenantId,
      'p_actor_id': request.actorId,
      'p_sales_order_id': request.salesOrderId,
      'p_source_version': request.sourceVersion,
      'p_idempotency_key': request.idempotencyKey,
      'p_acknowledge_warnings': request.acknowledgeWarnings,
    };
  }

  static Map<String, dynamic> preparePublishParams({
    required String tenantId,
    required String attemptId,
    required String idempotencyKey,
    required String payloadHash,
    required Map<String, Object?> canonicalInvoice,
  }) {
    return {
      'p_tenant_id': tenantId,
      'p_attempt_id': attemptId,
      'p_idempotency_key': idempotencyKey,
      'p_payload_hash': payloadHash,
      'p_canonical_payload': canonicalInvoice,
    };
  }

  static Map<String, dynamic> recordSuccessParams({
    required String tenantId,
    required String attemptId,
    required IssuanceSuccessEvidenceDto evidence,
  }) {
    return {
      'p_tenant_id': tenantId,
      'p_attempt_id': attemptId,
      'p_idempotency_key': evidence.idempotencyKey,
      'p_payload_hash': evidence.payloadHash,
      'p_provider_reference': evidence.providerReference,
      'p_invoice_number': evidence.invoiceNumber,
      'p_invoice_series': evidence.invoiceSeries,
      'p_issued_at': evidence.issuedAt.toUtc().toIso8601String(),
    };
  }

  static Map<String, dynamic> recordDefiniteFailureParams({
    required String tenantId,
    required String attemptId,
    required IssuanceDefiniteFailureEvidenceDto evidence,
  }) {
    return {
      'p_tenant_id': tenantId,
      'p_attempt_id': attemptId,
      'p_idempotency_key': evidence.idempotencyKey,
      'p_payload_hash': evidence.payloadHash,
      'p_provider_code': evidence.providerCode,
      'p_provider_message': evidence.providerMessage,
    };
  }

  static Map<String, dynamic> recordUndeterminedParams({
    required String tenantId,
    required String attemptId,
    required IssuanceUndeterminedEvidenceDto evidence,
  }) {
    return {
      'p_tenant_id': tenantId,
      'p_attempt_id': attemptId,
      'p_idempotency_key': evidence.idempotencyKey,
      'p_payload_hash': evidence.payloadHash,
      'p_reason_code': evidence.reasonCode,
    };
  }

  static Map<String, dynamic> orderInvoiceProjectionParams({
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

  static IssueInvoiceResultDto issueInvoiceResultFromRow(
    Map<String, dynamic> row,
  ) {
    final statusRaw = row['status'] as String?;
    if (statusRaw == null || statusRaw.isEmpty) {
      throw RpcException('issue_invoice returned missing status');
    }
    return IssueInvoiceResultDto(
      issuanceId: _requiredString(row, 'issuance_id'),
      attemptId: _requiredString(row, 'attempt_id'),
      status: _attemptStatusFromRpc(statusRaw),
    );
  }

  static PublishPreparationDto publishPreparationFromRow(
    Map<String, dynamic> row,
  ) {
    final actionRaw = row['action'] as String?;
    if (actionRaw == null || actionRaw.isEmpty) {
      throw RpcException('prepare_issuance_publish returned missing action');
    }
    return PublishPreparationDto(
      action: _publishPreparationActionFromRpc(actionRaw),
    );
  }

  static RecordIssuanceResultDto recordIssuanceResultFromRow(
    Map<String, dynamic> row,
  ) {
    final statusRaw = row['attempt_status'] as String?;
    if (statusRaw == null || statusRaw.isEmpty) {
      throw RpcException(
        'record issuance result returned missing attempt_status',
      );
    }
    final electronicInvoiceId = row['electronic_invoice_id'];
    return RecordIssuanceResultDto(
      attemptStatus: _attemptStatusFromRpc(statusRaw),
      electronicInvoiceId: electronicInvoiceId?.toString(),
    );
  }

  static OrderInvoiceProjectionDto orderInvoiceProjectionFromRow(
    Map<String, dynamic> row,
  ) {
    final salesOrderId = _requiredString(row, 'sales_order_id');
    final displayRaw = row['issuance_display_state'] as String?;
    if (displayRaw == null || displayRaw.isEmpty) {
      throw RpcException(
        'get_order_invoice_projection returned missing issuance_display_state',
      );
    }
    final actionsRaw = row['actions'];
    if (actionsRaw == null) {
      throw RpcException(
        'get_order_invoice_projection returned missing actions',
      );
    }
    return OrderInvoiceProjectionDto(
      salesOrderId: salesOrderId,
      issuanceDisplayState: _issuanceDisplayStateFromRpc(displayRaw),
      actions: _orderInvoiceActionsFromRpc(actionsRaw),
    );
  }

  static IssuanceAttemptStatus _attemptStatusFromRpc(String raw) {
    final normalized = switch (raw) {
      'PREPARING' => IssuanceAttemptStatus.preparing,
      'SUBMITTED' => IssuanceAttemptStatus.submitted,
      'WAITING_RESULT' => IssuanceAttemptStatus.waitingResult,
      'RECONCILING' => IssuanceAttemptStatus.reconciling,
      'SUCCEEDED' => IssuanceAttemptStatus.succeeded,
      'FAILED' => IssuanceAttemptStatus.failed,
      _ => throw RpcException('Unknown issuance attempt status: $raw'),
    };
    return normalized;
  }

  static PublishPreparationAction _publishPreparationActionFromRpc(String raw) {
    return switch (raw) {
      'CALL_PROVIDER' => PublishPreparationAction.callProvider,
      'RECONCILE_ONLY' => PublishPreparationAction.reconcileOnly,
      'SKIP' => PublishPreparationAction.skip,
      _ => throw RpcException('Unknown publish preparation action: $raw'),
    };
  }

  static IssuanceDisplayState _issuanceDisplayStateFromRpc(String raw) {
    return switch (raw) {
      'notIssued' => IssuanceDisplayState.notIssued,
      'processing' => IssuanceDisplayState.processing,
      'issued' => IssuanceDisplayState.issued,
      'failed' => IssuanceDisplayState.failed,
      _ => throw RpcException('Unknown issuance display state: $raw'),
    };
  }

  static List<OrderInvoiceAction> _orderInvoiceActionsFromRpc(Object? raw) {
    if (raw is! List) {
      throw RpcException('Projection actions must be a JSON array');
    }
    return raw
        .map((item) {
          final value = item?.toString();
          if (value == null || value.isEmpty) {
            throw RpcException('Projection action entry is empty');
          }
          return switch (value) {
            'preview' => OrderInvoiceAction.preview,
            'issue' => OrderInvoiceAction.issue,
            'retryIssue' => OrderInvoiceAction.retryIssue,
            'view' => OrderInvoiceAction.view,
            'downloadPdf' => OrderInvoiceAction.downloadPdf,
            'downloadXml' => OrderInvoiceAction.downloadXml,
            'send' => OrderInvoiceAction.send,
            'resend' => OrderInvoiceAction.resend,
            _ => throw RpcException('Unknown projection action: $value'),
          };
        })
        .toList(growable: false);
  }

  static String _requiredString(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value == null || value.toString().isEmpty) {
      throw RpcException('RPC row missing required field: $key');
    }
    return value.toString();
  }
}
