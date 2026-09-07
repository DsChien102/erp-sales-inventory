import 'partner_integration_event.dart';

final class PartnerProfileUpdatedIntegrationEvent
    extends PartnerIntegrationEvent {
  const PartnerProfileUpdatedIntegrationEvent({
    required super.id,
    required super.occurredOn,
    required super.tenantId,
    required super.partnerId,
  }) : super(eventType: type);

  static const String type = 'partner.partner.profile_updated';

  Map<String, dynamic> toPayload() {
    return <String, dynamic>{
      'id': id,
      'occurred_on': occurredOn.toUtc().toIso8601String(),
      'tenant_id': tenantId,
      'partner_id': partnerId,
      'event_type': type,
    };
  }

  factory PartnerProfileUpdatedIntegrationEvent.fromPayload(
    Map<String, dynamic> json,
  ) {
    final id = _requireNonEmptyString(
      json['id'] ?? json['idempotency_key'],
      'id',
    );
    final tenantId = _requireNonEmptyString(
      json['tenant_id'] ?? json['tenantId'],
      'tenant_id',
    );
    final partnerId = _requireNonEmptyString(
      json['partner_id'] ?? json['partnerId'],
      'partner_id',
    );

    final occurredOnRaw = json['occurred_on'] ?? json['occurredOn'];
    final DateTime occurredOn;
    if (occurredOnRaw is String && occurredOnRaw.trim().isNotEmpty) {
      occurredOn = DateTime.parse(occurredOnRaw).toUtc();
    } else if (occurredOnRaw is DateTime) {
      occurredOn = occurredOnRaw.toUtc();
    } else {
      throw const FormatException(
        'PartnerProfileUpdatedIntegrationEvent missing occurred_on',
      );
    }

    return PartnerProfileUpdatedIntegrationEvent(
      id: id,
      occurredOn: occurredOn,
      tenantId: tenantId,
      partnerId: partnerId,
    );
  }

  static String _requireNonEmptyString(Object? value, String fieldName) {
    if (value is! String || value.trim().isEmpty) {
      throw FormatException(
        'PartnerProfileUpdatedIntegrationEvent missing or empty $fieldName',
      );
    }
    return value.trim();
  }
}
