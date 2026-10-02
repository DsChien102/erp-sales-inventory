import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../data_access/electronic_invoice_rpc_mapper.dart';

/// Typed RPC param/row mapping for delivery start/result/read gateways.
abstract final class DeliveryRpcMapper {
  static Map<String, dynamic> startAutoParams(
    AutoDeliveryStartRequest request,
  ) {
    return <String, dynamic>{
      'p_tenant_id': request.tenantId,
      'p_electronic_invoice_id': request.electronicInvoiceId,
      'p_trigger_id': request.triggerId,
      'p_idempotency_key': request.idempotencyKey,
    };
  }

  static Map<String, dynamic> startManualParams(
    ManualDeliveryStartRequest request,
  ) {
    return <String, dynamic>{
      'p_tenant_id': request.tenantId,
      'p_actor_id': request.actorId,
      'p_sales_order_id': request.salesOrderId,
      'p_recipient_email': request.recipientEmail,
      'p_idempotency_key': request.idempotencyKey,
    };
  }

  static Map<String, dynamic> loadAttemptContextParams({
    required String tenantId,
    required String deliveryId,
    required int retryCount,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_delivery_id': deliveryId,
      'p_retry_count': retryCount,
    };
  }

  static Map<String, dynamic> prepareProviderCallParams({
    required String tenantId,
    required String deliveryId,
    required int retryCount,
    required String requestReference,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_delivery_id': deliveryId,
      'p_retry_count': retryCount,
      'p_request_reference': requestReference,
    };
  }

  static Map<String, dynamic> recordResultParams(DeliveryResultRecord record) {
    return <String, dynamic>{
      'p_tenant_id': record.tenantId,
      'p_delivery_id': record.deliveryId,
      'p_retry_count': record.retryCount,
      'p_expected_version': record.expectedDeliveryVersion,
      'p_outcome_kind': _outcomeKindToRpc(record.evidence.kind),
      'p_provider_reference': record.evidence.providerReference,
      'p_safe_code': record.evidence.safeCode,
      'p_failure_source': ElectronicInvoiceRpcMapper.failureSourceToRpc(
        record.evidence.failureSource,
      ),
    };
  }

  static Map<String, dynamic> recordCommandDeadLetterParams({
    required String tenantId,
    required String deliveryId,
    required int retryCount,
    required String safeFailureCode,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_delivery_id': deliveryId,
      'p_retry_count': retryCount,
      'p_safe_failure_code': safeFailureCode,
    };
  }

  static Map<String, dynamic> loadReconciliationContextParams({
    required String tenantId,
    required String reconciliationCaseId,
    required int checkSequence,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_reconciliation_case_id': reconciliationCaseId,
      'p_check_sequence': checkSequence,
    };
  }

  static Map<String, dynamic> recordReconciliationCheckParams(
    DeliveryReconciliationCheckRecord record,
  ) {
    return <String, dynamic>{
      'p_tenant_id': record.tenantId,
      'p_reconciliation_case_id': record.reconciliationCaseId,
      'p_expected_case_version': record.expectedCaseVersion,
      'p_check_sequence': record.checkSequence,
      'p_observation_kind': _observationKindToRpc(record.kind),
      'p_provider_reference': record.providerReference,
      'p_safe_code': record.safeCode,
    };
  }

  static DeliveryReconciliationContextDto reconciliationContextFromRow(
    Map<String, dynamic> row,
  ) {
    return DeliveryReconciliationContextDto(
      tenantId: _requiredString(row, 'tenant_id'),
      reconciliationCaseId: _requiredString(row, 'reconciliation_case_id'),
      deliveryId: _requiredString(row, 'delivery_id'),
      providerConnectionId: _requiredString(row, 'provider_connection_id'),
      supportsDeliveryResultObservation: _requiredBool(
        row,
        'supports_delivery_result_observation',
      ),
      checkSequence: _requiredInt(row, 'check_sequence'),
      caseVersion: _requiredInt(row, 'case_version'),
      providerDeliveryReference: row['provider_delivery_reference'] as String?,
    );
  }

  static DeliveryReconciliationResultDto reconciliationResultFromRow(
    Map<String, dynamic> row,
  ) {
    return DeliveryReconciliationResultDto(
      caseStatus: _reconciliationCaseStatusFromRpc(
        _requiredString(row, 'case_status'),
      ),
      deliveryStatus: deliveryStatusFromRpc(
        _requiredString(row, 'delivery_status'),
      ),
      nextCheckAt: _optionalDateTime(row, 'next_check_at'),
      hasSecondaryAttention: _requiredBool(row, 'has_secondary_attention'),
    );
  }

  static Map<String, dynamic> sendSheetContextParams({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_actor_id': actorId,
      'p_sales_order_id': salesOrderId,
    };
  }

  static Map<String, dynamic> historyParams({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_actor_id': actorId,
      'p_sales_order_id': salesOrderId,
    };
  }

  static AutoDeliveryResultDto autoDeliveryResultFromRow(
    Map<String, dynamic> row,
  ) {
    final dispositionRaw = _requiredString(row, 'disposition');
    final disposition = switch (dispositionRaw) {
      'started' => AutoDeliveryDisposition.started,
      'skipped' => AutoDeliveryDisposition.skipped,
      _ => throw RpcException(
        'Unknown auto delivery disposition: $dispositionRaw',
      ),
    };
    return AutoDeliveryResultDto(
      disposition: disposition,
      deliveryId: row['delivery_id']?.toString(),
      skipReason: disposition == AutoDeliveryDisposition.skipped
          ? _skipReasonFromRpc(row['skip_reason']?.toString())
          : null,
    );
  }

  static SendInvoiceResultDto sendInvoiceResultFromRow(
    Map<String, dynamic> row,
  ) {
    return SendInvoiceResultDto(
      deliveryId: _requiredString(row, 'delivery_id'),
      status: deliveryStatusFromRpc(_requiredString(row, 'status')),
    );
  }

  static DeliveryAttemptContextDto attemptContextFromRow(
    Map<String, dynamic> row,
  ) {
    return DeliveryAttemptContextDto(
      tenantId: _requiredString(row, 'tenant_id'),
      deliveryId: _requiredString(row, 'delivery_id'),
      retryCount: _requiredInt(row, 'retry_count'),
      deliveryVersion: _requiredInt(row, 'delivery_version'),
      providerConnectionId: _requiredString(row, 'provider_connection_id'),
      providerTransactionId: _requiredString(row, 'provider_transaction_id'),
      invoiceSeries: _requiredString(row, 'invoice_series'),
      recipientEmail: _requiredString(row, 'recipient_email'),
      recipientName: row['recipient_name']?.toString(),
    );
  }

  static PrepareDeliveryProviderCallResult prepareResultFromRow(
    Map<String, dynamic> row,
  ) {
    final action = _requiredString(row, 'action');
    return switch (action) {
      'CALL_PROVIDER' => PrepareDeliveryCallProvider(
        providerContext: DeliveryProviderContextDto(
          tenantId: '', // filled by gateway from request tenant
          providerConnectionId: _requiredString(row, 'provider_connection_id'),
          providerTransactionId: _requiredString(
            row,
            'provider_transaction_id',
          ),
          invoiceSeries: _requiredString(row, 'invoice_series'),
          recipientEmail: _requiredString(row, 'recipient_email'),
          recipientName: row['recipient_name']?.toString(),
        ),
        deliveryVersion: _requiredInt(row, 'delivery_version'),
      ),
      'SKIP' => const PrepareDeliverySkip(),
      'RECORD_UNKNOWN' => PrepareDeliveryRecordUnknown(
        deliveryVersion: _requiredInt(row, 'delivery_version'),
      ),
      _ => throw RpcException('Unknown prepare delivery action: $action'),
    };
  }

  static PrepareDeliveryProviderCallResult prepareResultFromRowWithTenant({
    required Map<String, dynamic> row,
    required String tenantId,
  }) {
    final mapped = prepareResultFromRow(row);
    if (mapped is PrepareDeliveryCallProvider) {
      return PrepareDeliveryCallProvider(
        providerContext: DeliveryProviderContextDto(
          tenantId: tenantId,
          providerConnectionId: mapped.providerContext.providerConnectionId,
          providerTransactionId: mapped.providerContext.providerTransactionId,
          invoiceSeries: mapped.providerContext.invoiceSeries,
          recipientEmail: mapped.providerContext.recipientEmail,
          recipientName: mapped.providerContext.recipientName,
        ),
        deliveryVersion: mapped.deliveryVersion,
      );
    }
    return mapped;
  }

  static RecordDeliveryResultDto recordResultFromRow(Map<String, dynamic> row) {
    return RecordDeliveryResultDto(
      deliveryStatus: deliveryStatusFromRpc(
        _requiredString(row, 'delivery_status'),
      ),
      displayState: deliveryDisplayStateFromRpc(
        _requiredString(row, 'display_state'),
      ),
      hasSecondaryAttention: _requiredBool(row, 'has_secondary_attention'),
    );
  }

  static SendInvoiceSheetContextDto sendSheetContextFromRow(
    Map<String, dynamic> row,
  ) {
    final sourceRaw = row['suggested_email_source']?.toString();
    return SendInvoiceSheetContextDto(
      mode: switch (_requiredString(row, 'mode')) {
        'send' => SendInvoiceSheetMode.send,
        'resend' => SendInvoiceSheetMode.resend,
        final other => throw RpcException('Unknown send sheet mode: $other'),
      },
      suggestedEmail: row['suggested_email']?.toString(),
      suggestedEmailSource: sourceRaw == null || sourceRaw.isEmpty
          ? null
          : recipientSourceFromRpc(sourceRaw),
      history: deliveryItemsFromRpc(row['history']),
      operationLocked: _requiredBool(row, 'operation_locked'),
      displayState: deliveryDisplayStateFromRpc(
        _requiredString(row, 'display_state'),
      ),
    );
  }

  static InvoiceDeliveryHistoryDto historyFromRow(Map<String, dynamic> row) {
    return InvoiceDeliveryHistoryDto(
      deliveries: deliveryItemsFromRpc(row['deliveries']),
      displayState: deliveryDisplayStateFromRpc(
        _requiredString(row, 'display_state'),
      ),
      hasSecondaryAttention: _requiredBool(row, 'has_secondary_attention'),
    );
  }

  static List<InvoiceDeliveryItemDto> deliveryItemsFromRpc(Object? raw) {
    if (raw == null) {
      return const [];
    }
    if (raw is! List) {
      throw RpcException('Delivery history must be a JSON array');
    }
    return raw
        .map((item) {
          if (item is! Map) {
            throw RpcException('Delivery history item must be an object');
          }
          final row = Map<String, dynamic>.from(item);
          return InvoiceDeliveryItemDto(
            deliveryId: _requiredString(row, 'deliveryId'),
            deliveryNo: _requiredInt(row, 'deliveryNo'),
            kind: deliveryKindFromRpc(_requiredString(row, 'kind')),
            triggerType: deliveryTriggerFromRpc(
              _requiredString(row, 'triggerType'),
            ),
            recipientEmail: _requiredString(row, 'recipientEmail'),
            status: deliveryStatusFromRpc(_requiredString(row, 'status')),
            initiatedByActorType: deliveryActorFromRpc(
              _requiredString(row, 'initiatedByActorType'),
            ),
            initiatedByActorId: row['initiatedByActorId']?.toString(),
            startedAt: _requiredDateTime(row, 'startedAt'),
            completedAt: _optionalDateTime(row, 'completedAt'),
            failureCode: row['failureCode']?.toString(),
          );
        })
        .toList(growable: false);
  }

  static DeliveryStatus deliveryStatusFromRpc(String raw) {
    return switch (raw.toUpperCase()) {
      'PROCESSING' => DeliveryStatus.processing,
      'SUCCEEDED' => DeliveryStatus.succeeded,
      'FAILED' => DeliveryStatus.failed,
      'UNKNOWN' => DeliveryStatus.unknown,
      _ => throw RpcException('Unknown delivery status: $raw'),
    };
  }

  static DeliveryDisplayState deliveryDisplayStateFromRpc(String raw) {
    return switch (raw) {
      'NOT_SENT' || 'notSent' => DeliveryDisplayState.notSent,
      'SENDING' || 'sending' => DeliveryDisplayState.sending,
      'SENT' || 'sent' => DeliveryDisplayState.sent,
      'FAILED' || 'failed' => DeliveryDisplayState.failed,
      'UNKNOWN' || 'unknown' => DeliveryDisplayState.unknown,
      _ => throw RpcException('Unknown delivery display state: $raw'),
    };
  }

  static DeliveryKind deliveryKindFromRpc(String raw) {
    return switch (raw.toUpperCase()) {
      'INITIAL_SEND' || 'INITIAL' => DeliveryKind.initial,
      'RESEND' => DeliveryKind.resend,
      _ => throw RpcException('Unknown delivery kind: $raw'),
    };
  }

  static DeliveryTriggerType deliveryTriggerFromRpc(String raw) {
    return switch (raw.toUpperCase()) {
      'AUTOMATIC' => DeliveryTriggerType.automatic,
      'MANUAL' => DeliveryTriggerType.manual,
      _ => throw RpcException('Unknown delivery trigger: $raw'),
    };
  }

  static DeliveryActorType deliveryActorFromRpc(String raw) {
    return switch (raw.toUpperCase()) {
      'SYSTEM' => DeliveryActorType.system,
      'USER' => DeliveryActorType.user,
      _ => throw RpcException('Unknown delivery actor type: $raw'),
    };
  }

  static DeliveryRecipientSource recipientSourceFromRpc(String raw) {
    return switch (raw.toUpperCase()) {
      'CURRENT_PARTNER_PROFILE' =>
        DeliveryRecipientSource.currentPartnerProfile,
      'BUYER_INVOICE_SNAPSHOT' => DeliveryRecipientSource.buyerInvoiceSnapshot,
      'LAST_SUCCESSFUL_PARTNER_DELIVERY' =>
        DeliveryRecipientSource.lastSuccessfulPartnerDelivery,
      'LAST_INVOICE_DELIVERY' => DeliveryRecipientSource.lastInvoiceDelivery,
      'USER_INPUT' => DeliveryRecipientSource.userInput,
      _ => throw RpcException('Unknown recipient source: $raw'),
    };
  }

  static String _outcomeKindToRpc(DeliveryResultKind kind) {
    return switch (kind) {
      DeliveryResultKind.success => 'SUCCESS',
      DeliveryResultKind.definiteFailure => 'DEFINITE_FAILURE',
      DeliveryResultKind.retryableFailure => 'RETRYABLE_FAILURE',
      DeliveryResultKind.undetermined => 'UNDETERMINED',
    };
  }

  static String _observationKindToRpc(DeliveryObservationKind kind) {
    return switch (kind) {
      DeliveryObservationKind.succeeded => 'SUCCESS',
      DeliveryObservationKind.definiteFailure => 'DEFINITE_FAILURE',
      DeliveryObservationKind.undetermined => 'UNDETERMINED',
      DeliveryObservationKind.unsupported => 'UNSUPPORTED',
    };
  }

  static ReconciliationCaseStatus _reconciliationCaseStatusFromRpc(String raw) {
    return switch (raw.toUpperCase()) {
      'PENDING' => ReconciliationCaseStatus.pending,
      'RESOLVED' => ReconciliationCaseStatus.resolved,
      'UNRESOLVED' => ReconciliationCaseStatus.unresolved,
      _ => throw RpcException('Unknown reconciliation case status: $raw'),
    };
  }

  static AutoDeliverySkipReason _skipReasonFromRpc(String? raw) {
    return switch (raw) {
      'POLICY_OFF' => AutoDeliverySkipReason.policyOff,
      'INVALID_OR_MISSING_EMAIL' =>
        AutoDeliverySkipReason.invalidOrMissingEmail,
      'INITIAL_DELIVERY_ALREADY_CLAIMED' =>
        AutoDeliverySkipReason.initialDeliveryAlreadyClaimed,
      _ => throw RpcException('Unknown auto delivery skip reason: $raw'),
    };
  }

  static String _requiredString(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value == null || value.toString().isEmpty) {
      throw RpcException('RPC row missing required field: $key');
    }
    return value.toString();
  }

  static int _requiredInt(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    throw RpcException('RPC row missing required int field: $key');
  }

  static bool _requiredBool(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is bool) {
      return value;
    }
    throw RpcException('RPC row missing required bool field: $key');
  }

  static DateTime _requiredDateTime(Map<String, dynamic> row, String key) {
    final raw = _requiredString(row, key);
    try {
      return DateTime.parse(raw).toUtc();
    } on FormatException {
      throw RpcException('RPC row has malformed timestamp: $key');
    }
  }

  static DateTime? _optionalDateTime(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value == null || value.toString().isEmpty) {
      return null;
    }
    try {
      return DateTime.parse(value.toString()).toUtc();
    } on FormatException {
      throw RpcException('RPC row has malformed timestamp: $key');
    }
  }
}
