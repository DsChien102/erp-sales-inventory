import 'einvoice_integration_event.dart';

/// Outcome category for external e-invoice provider issuance results.
enum ProviderIssuanceOutcome {
  success('success'),
  definiteFailure('definiteFailure'),
  undetermined('undetermined');

  const ProviderIssuanceOutcome(this.serializedName);

  final String serializedName;

  static ProviderIssuanceOutcome fromString(String value) {
    final normalized = value.trim();
    if (normalized == 'success') {
      return ProviderIssuanceOutcome.success;
    }
    if (normalized == 'definiteFailure' ||
        normalized == 'definite_failure' ||
        normalized == 'failure') {
      return ProviderIssuanceOutcome.definiteFailure;
    }
    if (normalized == 'undetermined') {
      return ProviderIssuanceOutcome.undetermined;
    }
    throw FormatException(
      'Invalid ProviderIssuanceOutcome discriminator: $value',
    );
  }
}

/// Integration event published when a provider issuance result (terminal or undetermined) is received.
final class ProviderIssuanceResultReceivedIntegrationEvent extends EInvoiceIntegrationEvent {
  const ProviderIssuanceResultReceivedIntegrationEvent._({
    required super.id,
    required super.occurredOn,
    required super.tenantId,
    required this.attemptId,
    required this.correlationId,
    required this.idempotencyKey,
    required this.payloadHash,
    required this.outcome,
    this.providerReference,
    this.invoiceNumber,
    this.invoiceSeries,
    this.issuedAt,
    this.errorCode,
    this.errorMessage,
    this.reasonCode,
  }) : super(eventType: type);

  static const String type = 'einvoice.provider.issuance_result_received';

  final String attemptId;
  final String correlationId;
  final String idempotencyKey;
  final String payloadHash;
  final ProviderIssuanceOutcome outcome;

  /// Provider's internal reference ID if known.
  final String? providerReference;

  /// Authorized invoice number (success outcome).
  final String? invoiceNumber;

  /// Authorized invoice series/symbol (success outcome).
  final String? invoiceSeries;

  /// Provider timestamp when invoice was issued (success outcome).
  final DateTime? issuedAt;

  /// Provider failure code (definiteFailure outcome).
  final String? errorCode;

  /// Provider failure explanation (definiteFailure outcome).
  final String? errorMessage;

  /// Reason code explaining undetermined state (undetermined outcome).
  final String? reasonCode;

  factory ProviderIssuanceResultReceivedIntegrationEvent.success({
    required String id,
    required DateTime occurredOn,
    required String tenantId,
    required String attemptId,
    required String correlationId,
    required String idempotencyKey,
    required String payloadHash,
    String? providerReference,
    required String invoiceNumber,
    required String invoiceSeries,
    required DateTime issuedAt,
  }) {
    return ProviderIssuanceResultReceivedIntegrationEvent._(
      id: _requireNonEmptyString(id, 'id'),
      occurredOn: occurredOn.toUtc(),
      tenantId: _requireNonEmptyString(tenantId, 'tenantId'),
      attemptId: _requireNonEmptyString(attemptId, 'attemptId'),
      correlationId: _requireNonEmptyString(correlationId, 'correlationId'),
      idempotencyKey: _requireNonEmptyString(idempotencyKey, 'idempotencyKey'),
      payloadHash: _requireNonEmptyString(payloadHash, 'payloadHash'),
      outcome: ProviderIssuanceOutcome.success,
      providerReference: _cleanOptional(providerReference),
      invoiceNumber: _requireNonEmptyString(invoiceNumber, 'invoiceNumber'),
      invoiceSeries: _requireNonEmptyString(invoiceSeries, 'invoiceSeries'),
      issuedAt: issuedAt.toUtc(),
    );
  }

  factory ProviderIssuanceResultReceivedIntegrationEvent.definiteFailure({
    required String id,
    required DateTime occurredOn,
    required String tenantId,
    required String attemptId,
    required String correlationId,
    required String idempotencyKey,
    required String payloadHash,
    String? providerReference,
    required String errorCode,
    required String errorMessage,
  }) {
    return ProviderIssuanceResultReceivedIntegrationEvent._(
      id: _requireNonEmptyString(id, 'id'),
      occurredOn: occurredOn.toUtc(),
      tenantId: _requireNonEmptyString(tenantId, 'tenantId'),
      attemptId: _requireNonEmptyString(attemptId, 'attemptId'),
      correlationId: _requireNonEmptyString(correlationId, 'correlationId'),
      idempotencyKey: _requireNonEmptyString(idempotencyKey, 'idempotencyKey'),
      payloadHash: _requireNonEmptyString(payloadHash, 'payloadHash'),
      outcome: ProviderIssuanceOutcome.definiteFailure,
      providerReference: _cleanOptional(providerReference),
      errorCode: _requireNonEmptyString(errorCode, 'errorCode'),
      errorMessage: _requireNonEmptyString(errorMessage, 'errorMessage'),
    );
  }

  factory ProviderIssuanceResultReceivedIntegrationEvent.undetermined({
    required String id,
    required DateTime occurredOn,
    required String tenantId,
    required String attemptId,
    required String correlationId,
    required String idempotencyKey,
    required String payloadHash,
    String? providerReference,
    required String reasonCode,
  }) {
    return ProviderIssuanceResultReceivedIntegrationEvent._(
      id: _requireNonEmptyString(id, 'id'),
      occurredOn: occurredOn.toUtc(),
      tenantId: _requireNonEmptyString(tenantId, 'tenantId'),
      attemptId: _requireNonEmptyString(attemptId, 'attemptId'),
      correlationId: _requireNonEmptyString(correlationId, 'correlationId'),
      idempotencyKey: _requireNonEmptyString(idempotencyKey, 'idempotencyKey'),
      payloadHash: _requireNonEmptyString(payloadHash, 'payloadHash'),
      outcome: ProviderIssuanceOutcome.undetermined,
      providerReference: _cleanOptional(providerReference),
      reasonCode: _requireNonEmptyString(reasonCode, 'reasonCode'),
    );
  }

  @override
  Map<String, dynamic> toPayload() {
    final fields = <String, dynamic>{
      'attempt_id': attemptId,
      'correlation_id': correlationId,
      'idempotency_key': idempotencyKey,
      'payload_hash': payloadHash,
      'outcome': outcome.serializedName,
    };

    if (providerReference != null && providerReference!.trim().isNotEmpty) {
      fields['provider_reference'] = providerReference!.trim();
    }

    switch (outcome) {
      case ProviderIssuanceOutcome.success:
        fields['invoice_number'] = invoiceNumber;
        fields['invoice_series'] = invoiceSeries;
        fields['issued_at'] = issuedAt!.toUtc().toIso8601String();
        break;
      case ProviderIssuanceOutcome.definiteFailure:
        fields['error_code'] = errorCode;
        fields['error_message'] = errorMessage;
        break;
      case ProviderIssuanceOutcome.undetermined:
        fields['reason_code'] = reasonCode;
        break;
    }

    return envelopePayload(fields);
  }

  factory ProviderIssuanceResultReceivedIntegrationEvent.fromPayload(
    Map<String, dynamic> json,
  ) {
    final id = _requireNonEmptyString(
      json['id'] ?? json['event_id'],
      'id',
    );
    final tenantId = _requireNonEmptyString(
      json['tenant_id'] ?? json['tenantId'],
      'tenant_id',
    );
    final attemptId = _requireNonEmptyString(
      json['attempt_id'] ?? json['attemptId'],
      'attempt_id',
    );
    final correlationId = _requireNonEmptyString(
      json['correlation_id'] ?? json['correlationId'],
      'correlation_id',
    );
    final idempotencyKey = _requireNonEmptyString(
      json['idempotency_key'] ?? json['idempotencyKey'],
      'idempotency_key',
    );
    final payloadHash = _requireNonEmptyString(
      json['payload_hash'] ?? json['payloadHash'],
      'payload_hash',
    );

    final occurredOnRaw = json['occurred_on'] ?? json['occurredOn'];
    final DateTime occurredOn;
    if (occurredOnRaw is String && occurredOnRaw.trim().isNotEmpty) {
      occurredOn = DateTime.parse(occurredOnRaw).toUtc();
    } else if (occurredOnRaw is DateTime) {
      occurredOn = occurredOnRaw.toUtc();
    } else {
      throw const FormatException(
        'ProviderIssuanceResultReceivedIntegrationEvent missing occurred_on',
      );
    }

    final outcomeRaw = _requireNonEmptyString(
      json['outcome'] ?? json['outcome_type'],
      'outcome',
    );
    final outcome = ProviderIssuanceOutcome.fromString(outcomeRaw);

    final providerRef = _cleanOptional(
      (json['provider_reference'] ?? json['providerReference']) as String?,
    );

    switch (outcome) {
      case ProviderIssuanceOutcome.success:
        final invoiceNumber = _requireNonEmptyString(
          json['invoice_number'] ?? json['invoiceNumber'],
          'invoice_number',
        );
        final invoiceSeries = _requireNonEmptyString(
          json['invoice_series'] ?? json['invoiceSeries'],
          'invoice_series',
        );
        final issuedAtRaw = json['issued_at'] ?? json['issuedAt'];
        final DateTime issuedAt;
        if (issuedAtRaw is String && issuedAtRaw.trim().isNotEmpty) {
          issuedAt = DateTime.parse(issuedAtRaw).toUtc();
        } else if (issuedAtRaw is DateTime) {
          issuedAt = issuedAtRaw.toUtc();
        } else {
          throw const FormatException(
            'ProviderIssuanceResultReceivedIntegrationEvent success missing issued_at',
          );
        }

        return ProviderIssuanceResultReceivedIntegrationEvent.success(
          id: id,
          occurredOn: occurredOn,
          tenantId: tenantId,
          attemptId: attemptId,
          correlationId: correlationId,
          idempotencyKey: idempotencyKey,
          payloadHash: payloadHash,
          providerReference: providerRef,
          invoiceNumber: invoiceNumber,
          invoiceSeries: invoiceSeries,
          issuedAt: issuedAt,
        );

      case ProviderIssuanceOutcome.definiteFailure:
        final errorCode = _requireNonEmptyString(
          json['error_code'] ?? json['errorCode'],
          'error_code',
        );
        final errorMessage = _requireNonEmptyString(
          json['error_message'] ?? json['errorMessage'],
          'error_message',
        );

        return ProviderIssuanceResultReceivedIntegrationEvent.definiteFailure(
          id: id,
          occurredOn: occurredOn,
          tenantId: tenantId,
          attemptId: attemptId,
          correlationId: correlationId,
          idempotencyKey: idempotencyKey,
          payloadHash: payloadHash,
          providerReference: providerRef,
          errorCode: errorCode,
          errorMessage: errorMessage,
        );

      case ProviderIssuanceOutcome.undetermined:
        final reasonCode = _requireNonEmptyString(
          json['reason_code'] ?? json['reasonCode'],
          'reason_code',
        );

        return ProviderIssuanceResultReceivedIntegrationEvent.undetermined(
          id: id,
          occurredOn: occurredOn,
          tenantId: tenantId,
          attemptId: attemptId,
          correlationId: correlationId,
          idempotencyKey: idempotencyKey,
          payloadHash: payloadHash,
          providerReference: providerRef,
          reasonCode: reasonCode,
        );
    }
  }

  static String _requireNonEmptyString(Object? value, String fieldName) {
    if (value is! String || value.trim().isEmpty) {
      throw FormatException(
        'ProviderIssuanceResultReceivedIntegrationEvent missing or empty $fieldName',
      );
    }
    return value.trim();
  }

  static String? _cleanOptional(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
