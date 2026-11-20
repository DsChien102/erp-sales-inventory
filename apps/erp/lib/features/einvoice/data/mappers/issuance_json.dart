import '../../logic/issuance_readiness_evaluator.dart';
import '../models.dart';

abstract final class EInvoiceIssuanceJson {
  static IssuanceReadinessInput issuanceReadinessInputFromRow(
    Map<String, dynamic> row,
  ) {
    final warnings = (row['config_warnings'] as List<dynamic>? ?? const [])
        .map(
          (raw) => raw is Map
              ? ReadinessWarning(
                  code: (raw['code'] as String?) ?? '',
                  message: (raw['message'] as String?) ?? '',
                )
              : ReadinessWarning(code: raw.toString(), message: raw.toString()),
        )
        .toList(growable: false);

    final buyerTypeStr = row['buyer_type'] as String? ?? 'retail';
    final buyerType = BuyerType.values.firstWhere(
      (e) => e.name == buyerTypeStr,
      orElse: () => BuyerType.retail,
    );

    final buyer = EffectiveBuyerInvoiceData(
      buyerType: buyerType,
      name: row['buyer_name'] as String? ?? '',
      email: row['buyer_email'] as String?,
      taxCode: row['buyer_tax_code'] as String?,
      address: row['buyer_address'] as String?,
    );

    final completionStateStr =
        row['buyer_completion_state'] as String? ?? 'locked';
    final buyerCompletionState = BuyerCompletionStatus.values.firstWhere(
      (e) => e.name == completionStateStr,
      orElse: () => BuyerCompletionStatus.locked,
    );

    return IssuanceReadinessInput(
      orderCompleted: row['order_completed'] as bool? ?? false,
      hasElectronicInvoice: row['has_electronic_invoice'] as bool? ?? false,
      hasActiveOperation: row['has_active_operation'] as bool? ?? false,
      configReady: row['config_ready'] as bool? ?? false,
      providerConnected: row['provider_connected'] as bool? ?? false,
      providerSupportsPreview:
          row['provider_supports_preview'] as bool? ?? false,
      buyer: buyer,
      buyerCompletionState: buyerCompletionState,
      commercialDataMappable: row['commercial_data_mappable'] as bool? ?? true,
      configWarnings: warnings,
      sourceBlockers: ((row['source_blockers'] as List?) ?? const [])
          .map((code) => code.toString())
          .toList(),
    );
  }

  static InvoicePreviewResultDto invoicePreviewResultFromRow(
    Map<String, dynamic> row,
  ) {
    return InvoicePreviewResultDto(
      viewerRef: row['viewer_ref'] as String?,
      failureCode: row['failure_code'] as String?,
      warnings: const [],
    );
  }

  static IssueInvoiceResultDto issueInvoiceResultFromRow(
    Map<String, dynamic> row,
  ) {
    final statusRaw = row['status'] as String?;
    if (statusRaw == null || statusRaw.isEmpty) {
      throw const FormatException('issue_invoice returned missing status');
    }
    return IssueInvoiceResultDto(
      issuanceId: _requiredString(row, 'issuance_id'),
      attemptId: _requiredString(row, 'attempt_id'),
      status: _attemptStatusFromRpc(statusRaw),
    );
  }

  static OrderInvoiceProjectionDto orderInvoiceProjectionFromRow(
    Map<String, dynamic> row,
  ) {
    final salesOrderId = _requiredString(row, 'sales_order_id');
    final displayRaw = row['issuance_display_state'] as String?;
    if (displayRaw == null || displayRaw.isEmpty) {
      throw const FormatException(
        'get_order_invoice_projection returned missing issuance_display_state',
      );
    }
    final actionsRaw = row['actions'];
    if (actionsRaw == null) {
      throw const FormatException(
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

  static IssuanceAttemptStatus _attemptStatusFromRpc(String raw) {
    return switch (raw) {
      'PREPARING' => IssuanceAttemptStatus.preparing,
      'SUBMITTED' => IssuanceAttemptStatus.submitted,
      'WAITING_RESULT' => IssuanceAttemptStatus.waitingResult,
      'RECONCILING' => IssuanceAttemptStatus.reconciling,
      'SUCCEEDED' => IssuanceAttemptStatus.succeeded,
      'FAILED' => IssuanceAttemptStatus.failed,
      _ => throw FormatException('Unknown issuance attempt status: $raw'),
    };
  }

  static IssuanceDisplayState _issuanceDisplayStateFromRpc(String raw) {
    return switch (raw) {
      'notIssued' => IssuanceDisplayState.notIssued,
      'processing' => IssuanceDisplayState.processing,
      'issued' => IssuanceDisplayState.issued,
      'failed' => IssuanceDisplayState.failed,
      _ => throw FormatException('Unknown issuance display state: $raw'),
    };
  }

  static DeliveryDisplayState _deliveryDisplayStateFromRpc(String raw) {
    return switch (raw) {
      'NOT_SENT' || 'notSent' => DeliveryDisplayState.notSent,
      'SENDING' || 'sending' => DeliveryDisplayState.sending,
      'SENT' || 'sent' => DeliveryDisplayState.sent,
      'FAILED' || 'failed' => DeliveryDisplayState.failed,
      'UNKNOWN' || 'unknown' => DeliveryDisplayState.unknown,
      _ => throw FormatException('Unknown delivery display state: $raw'),
    };
  }

  static List<OrderInvoiceAction> _orderInvoiceActionsFromRpc(Object? raw) {
    if (raw is! List) {
      throw const FormatException('Projection actions must be a JSON array');
    }
    return raw
        .map((item) {
          final value = item?.toString();
          if (value == null || value.isEmpty) {
            throw const FormatException('Projection action entry is empty');
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
            _ => throw FormatException('Unknown projection action: $value'),
          };
        })
        .toList(growable: false);
  }

  static InternalFinalizationStatus _internalFinalizationStatusFromRpc(
    String raw,
  ) {
    return switch (raw.toLowerCase()) {
      'pending' => InternalFinalizationStatus.pending,
      'completed' => InternalFinalizationStatus.completed,
      'unresolved' => InternalFinalizationStatus.unresolved,
      _ => throw FormatException('Unknown internal finalization status: $raw'),
    };
  }

  static String _requiredString(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value == null || value.toString().isEmpty) {
      throw FormatException('RPC row missing required field: $key');
    }
    return value.toString();
  }
}

