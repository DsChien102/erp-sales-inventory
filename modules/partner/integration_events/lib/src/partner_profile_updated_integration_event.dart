import 'partner_integration_event.dart';

final class PartnerProfileUpdatedIntegrationEvent extends PartnerIntegrationEvent {
  const PartnerProfileUpdatedIntegrationEvent({
    required super.id,
    required super.occurredOn,
    required super.tenantId,
    required super.partnerId,
  }) : super(eventType: type);

  static const String type = 'partner.partner.profile_updated';
}
