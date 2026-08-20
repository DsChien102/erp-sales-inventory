import 'package:vet45_shared_infrastructure/infrastructure.dart';

final class OtherIntegrationEvent extends TenantScopedIntegrationEvent {
  OtherIntegrationEvent({
    required super.id,
    required super.occurredOn,
    required super.tenantId,
  }) : super(eventType: type);

  static const type = 'other.integration_event';

  @override
  Map<String, dynamic> toPayload() {
    return <String, dynamic>{
      'id': id,
      'occurred_on': occurredOn.toUtc().toIso8601String(),
      'tenant_id': tenantId,
    };
  }

  factory OtherIntegrationEvent.fromPayload(Map<String, dynamic> json) {
    return OtherIntegrationEvent(
      id: TenantScopedIntegrationEvent.resolveId(json),
      occurredOn: DateTime.parse(json['occurred_on'] as String).toUtc(),
      tenantId: json['tenant_id'] as String,
    );
  }
}
