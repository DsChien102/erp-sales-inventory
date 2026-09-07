import 'einvoice_integration_event.dart';

/// Published when delivery result is recorded or updated.
final class DeliveryResultRecordedIntegrationEvent extends EInvoiceIntegrationEvent {
  const DeliveryResultRecordedIntegrationEvent({
    required super.id,
    required super.occurredOn,
    required super.tenantId,
    required this.salesOrderId,
    required this.deliveryId,
    required this.deliveryStatus,
    required this.deliveryDisplayState,
    required this.deliveryVersion,
    required this.hasSecondaryAttention,
  }) : super(eventType: type);

  static const String type = 'einvoice.delivery.result_recorded';

  static const Set<String> _allowedStatuses = {
    'processing',
    'succeeded',
    'failed',
    'unknown',
  };

  static const Set<String> _allowedDisplayStates = {
    'notSent',
    'sending',
    'sent',
    'failed',
  };

  final String salesOrderId;
  final String deliveryId;
  final String deliveryStatus;
  final String deliveryDisplayState;
  final int deliveryVersion;
  final bool hasSecondaryAttention;

  @override
  Map<String, dynamic> toPayload() => envelopePayload(<String, dynamic>{
    'sales_order_id': salesOrderId,
    'delivery_id': deliveryId,
    'delivery_status': deliveryStatus,
    'delivery_display_state': deliveryDisplayState,
    'delivery_version': deliveryVersion,
    'has_secondary_attention': hasSecondaryAttention,
  });

  factory DeliveryResultRecordedIntegrationEvent.fromPayload(
    Map<String, dynamic> payload,
  ) {
    final status = _requiredString(payload, 'delivery_status');
    if (!_allowedStatuses.contains(status)) {
      throw FormatException('Malformed delivery_status: $status');
    }
    final displayState = _requiredString(payload, 'delivery_display_state');
    if (!_allowedDisplayStates.contains(displayState)) {
      throw FormatException('Malformed delivery_display_state: $displayState');
    }

    return DeliveryResultRecordedIntegrationEvent(
      id: _requiredString(payload, 'id'),
      occurredOn: _requiredDateTime(payload, 'occurred_on'),
      tenantId: _requiredString(payload, 'tenant_id'),
      salesOrderId: _requiredString(payload, 'sales_order_id'),
      deliveryId: _requiredString(payload, 'delivery_id'),
      deliveryStatus: status,
      deliveryDisplayState: displayState,
      deliveryVersion: _requiredInt(payload, 'delivery_version'),
      hasSecondaryAttention: _requiredBool(payload, 'has_secondary_attention'),
    );
  }

  static String _requiredString(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Missing or empty $key');
    }
    return value.trim();
  }

  static DateTime _requiredDateTime(Map<String, dynamic> payload, String key) {
    final raw = _requiredString(payload, key);
    try {
      return DateTime.parse(raw).toUtc();
    } on FormatException {
      throw FormatException('Malformed $key timestamp');
    }
  }

  static int _requiredInt(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    throw FormatException('Missing or invalid $key');
  }

  static bool _requiredBool(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value is bool) {
      return value;
    }
    throw FormatException('Missing or invalid $key');
  }
}
