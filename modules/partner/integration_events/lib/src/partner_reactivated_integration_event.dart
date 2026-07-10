import 'partner_integration_event.dart';

final class PartnerReactivatedIntegrationEvent extends PartnerIntegrationEvent {
  const PartnerReactivatedIntegrationEvent({
    required super.id,
    required super.occurredOn,
    required super.tenantId,
    required super.partnerId,
    this.reason,
  }) : super(eventType: type);

  static const String type = 'partner.partner.reactivated';

  final String? reason;
}
