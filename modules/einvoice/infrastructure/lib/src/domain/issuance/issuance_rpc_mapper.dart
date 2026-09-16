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

  static Map<String, dynamic> retryIssuanceParams(
    RetryIssuanceStartRequest request,
  ) {
    return {
      'p_tenant_id': request.tenantId,
      'p_actor_id': request.actorId,
      'p_sales_order_id': request.salesOrderId,
      'p_expected_order_version': request.expectedOrderVersion.toString(),
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

  static Map<String, dynamic> markProviderCallStartedParams({
    required String tenantId,
    required String attemptId,
  }) {
    return {'p_tenant_id': tenantId, 'p_attempt_id': attemptId};
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

  static Map<String, dynamic> recordRetryableProviderRejectionParams({
    required String tenantId,
    required String attemptId,
    required String sourceCommandId,
    required IssuanceRetryableProviderRejectionEvidenceDto evidence,
    required Duration retryAfter,
  }) {
    return {
      'p_tenant_id': tenantId,
      'p_attempt_id': attemptId,
      'p_source_command_id': sourceCommandId,
      'p_idempotency_key': evidence.idempotencyKey,
      'p_payload_hash': evidence.payloadHash,
      'p_provider_code': evidence.providerCode,
      'p_provider_message': evidence.providerMessage,
      'p_retry_after_seconds': retryAfter.inSeconds,
    };
  }

  static Map<String, dynamic> recordCommandIntegrityFailureParams({
    required String tenantId,
    required String attemptId,
    required String reasonCode,
  }) {
    return {
      'p_tenant_id': tenantId,
      'p_attempt_id': attemptId,
      'p_reason_code': reasonCode,
    };
  }

  static Map<String, dynamic> recordPublishCommandDeadLetterParams({
    required String tenantId,
    required String attemptId,
    required String reasonCode,
  }) {
    return {
      'p_tenant_id': tenantId,
      'p_attempt_id': attemptId,
      'p_reason_code': reasonCode,
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
    final deliveryRaw = row['delivery_display_state'] as String?;
    final secondaryRaw = row['has_secondary_attention'];
    return OrderInvoiceProjectionDto(
      salesOrderId: salesOrderId,
      issuanceDisplayState: _issuanceDisplayStateFromRpc(displayRaw),
      deliveryDisplayState: deliveryRaw == null || deliveryRaw.isEmpty
          ? null
          : _deliveryDisplayStateFromRpc(deliveryRaw),
      hasSecondaryAttention: secondaryRaw is bool ? secondaryRaw : false,
      deliveryPending: row['delivery_pending'] as bool? ?? false,
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

  static DeliveryDisplayState _deliveryDisplayStateFromRpc(String raw) {
    return switch (raw) {
      'NOT_SENT' || 'notSent' => DeliveryDisplayState.notSent,
      'SENDING' || 'sending' => DeliveryDisplayState.sending,
      'SENT' || 'sent' => DeliveryDisplayState.sent,
      'FAILED' || 'failed' => DeliveryDisplayState.failed,
      'UNKNOWN' || 'unknown' => DeliveryDisplayState.unknown,
      _ => throw RpcException('Unknown delivery display state: $raw'),
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

  static Map<String, dynamic> startAutoIssuanceParams(
    AutoIssuanceStartRequest request,
  ) {
    return {
      'p_tenant_id': request.tenantId,
      'p_sales_order_id': request.salesOrderId,
      'p_trigger_key': request.triggerKey,
      'p_idempotency_key': request.idempotencyKey,
    };
  }

  static Map<String, dynamic> reevaluateAutoIssuanceParams(
    AutoIssuanceReevaluationRequest request,
  ) {
    return {
      'p_tenant_id': request.tenantId,
      'p_process_id': request.processId,
      'p_source_event_id': request.sourceEventId,
    };
  }

  static Map<String, dynamic> listOpenAutoIssuanceProcessesParams({
    required String tenantId,
    required String partnerId,
  }) {
    return {'p_tenant_id': tenantId, 'p_partner_id': partnerId};
  }

  static AutoIssuanceResultDto autoIssuanceResultFromRow(
    Map<String, dynamic> row,
  ) {
    final startedRaw = row['started'];
    if (startedRaw is! bool) {
      throw RpcException('auto issuance result missing started boolean');
    }
    return AutoIssuanceResultDto(
      started: startedRaw,
      skipped: (row['skipped'] as bool?) ?? !startedRaw,
      processId: row['process_id']?.toString(),
      attemptId: row['attempt_id']?.toString(),
      status: row['status']?.toString(),
      reason: row['reason']?.toString(),
    );
  }

  static OpenAutoIssuanceProcessDto openAutoIssuanceProcessFromRow(
    Map<String, dynamic> row,
  ) {
    return OpenAutoIssuanceProcessDto(
      processId: _requiredString(row, 'process_id'),
      salesOrderId: _requiredString(row, 'sales_order_id'),
      partnerId: row['partner_id']?.toString(),
      status: row['status']?.toString(),
    );
  }

  static Map<String, dynamic> openReconciliationCaseParams({
    required String tenantId,
    required String attemptId,
    required String reason,
  }) {
    return {
      'p_tenant_id': tenantId,
      'p_attempt_id': attemptId,
      'p_reason': reason,
    };
  }

  static Map<String, dynamic> claimReconciliationCaseParams({
    required String tenantId,
    required String caseId,
    required String workerId,
  }) {
    return {
      'p_tenant_id': tenantId,
      'p_case_id': caseId,
      'p_worker_id': workerId,
    };
  }

  static Map<String, dynamic> recordReconciliationPendingParams({
    required String tenantId,
    required String caseId,
    required String claimToken,
    required int nextDelaySeconds,
    required int checkSequence,
  }) {
    return {
      'p_tenant_id': tenantId,
      'p_case_id': caseId,
      'p_claim_token': claimToken,
      'p_next_delay_seconds': nextDelaySeconds,
      'p_check_sequence': checkSequence,
    };
  }

  static Map<String, dynamic> resolveReconciliationCaseParams({
    required String tenantId,
    required String caseId,
    required String outcome,
    Map<String, Object?>? evidence,
  }) {
    return {
      'p_tenant_id': tenantId,
      'p_case_id': caseId,
      'p_outcome': outcome,
      if (evidence != null) 'p_evidence': evidence,
    };
  }

  static Map<String, dynamic> recoverInternalFinalizationParams({
    required String tenantId,
    required String attemptId,
  }) {
    return {'p_tenant_id': tenantId, 'p_attempt_id': attemptId};
  }

  static Map<String, dynamic> getIssuanceAttemptStatusParams({
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

  static ReconciliationCaseDto reconciliationCaseFromRow(
    Map<String, dynamic> row,
  ) {
    final statusRaw = _requiredString(row, 'status');
    return ReconciliationCaseDto(
      caseId: _requiredString(row, 'case_id'),
      attemptId: _requiredString(row, 'attempt_id'),
      status: _reconciliationCaseStatusFromRpc(statusRaw),
    );
  }

  static ReconciliationPollContextDto reconciliationPollContextFromRow(
    Map<String, dynamic> row,
  ) {
    return ReconciliationPollContextDto(
      caseId: _requiredString(row, 'case_id'),
      attemptId: _requiredString(row, 'attempt_id'),
      claimToken: _requiredString(row, 'claim_token'),
      idempotencyKey: _requiredString(row, 'idempotency_key'),
      payloadHash: _requiredString(row, 'payload_hash'),
      invoiceSeries: _requiredString(row, 'invoice_series'),
      providerReference: row['provider_reference']?.toString(),
      reconciliationReasonCode: row['reconciliation_reason_code']?.toString(),
      checkSequence: (row['check_sequence'] as num).toInt(),
      maxChecks: (row['max_checks'] as num?)?.toInt() ?? 5,
    );
  }

  static RecoverInternalFinalizationResultDto
  recoverInternalFinalizationResultFromRow(Map<String, dynamic> row) {
    return RecoverInternalFinalizationResultDto(
      invoice: ElectronicInvoiceDto(
        electronicInvoiceId: _requiredString(row, 'electronic_invoice_id'),
        salesOrderId: _requiredString(row, 'sales_order_id'),
        invoiceNumber: row['invoice_number']?.toString(),
        providerInvoiceRef:
            row['provider_invoice_ref']?.toString() ??
            row['invoice_series']?.toString(),
      ),
    );
  }

  static IssuanceAttemptStatusDto issuanceAttemptStatusFromRow(
    Map<String, dynamic> row,
  ) {
    final statusRaw = _requiredString(row, 'status');
    final finStatusRaw = _requiredString(row, 'internal_finalization_status');
    return IssuanceAttemptStatusDto(
      attemptId: row['attempt_id']?.toString(),
      status: _attemptStatusFromRpc(statusRaw),
      internalFinalizationStatus: _internalFinalizationStatusFromRpc(
        finStatusRaw,
      ),
      hasElectronicInvoice: row['has_electronic_invoice'] == true,
      hasActiveOperation: row['has_active_operation'] == true,
      failureCode: row['failure_code']?.toString(),
      lastErrorMessage: row['last_error_message']?.toString(),
    );
  }

  static ReconciliationCaseStatus _reconciliationCaseStatusFromRpc(String raw) {
    return switch (raw.toUpperCase()) {
      'PENDING' => ReconciliationCaseStatus.pending,
      'RESOLVED' => ReconciliationCaseStatus.resolved,
      'UNRESOLVED' => ReconciliationCaseStatus.unresolved,
      _ => throw RpcException('Unknown reconciliation case status: $raw'),
    };
  }

  static InternalFinalizationStatus _internalFinalizationStatusFromRpc(
    String raw,
  ) {
    return switch (raw.toLowerCase()) {
      'pending' => InternalFinalizationStatus.pending,
      'completed' => InternalFinalizationStatus.completed,
      'unresolved' => InternalFinalizationStatus.unresolved,
      _ => throw RpcException('Unknown internal finalization status: $raw'),
    };
  }

  static String _requiredString(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value == null || value.toString().isEmpty) {
      throw RpcException('RPC row missing required field: $key');
    }
    return value.toString();
  }
}
