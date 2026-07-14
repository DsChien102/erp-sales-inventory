import 'partner_integration_event.dart';

final class PartnerTransformedIntegrationEvent extends PartnerIntegrationEvent {
  const PartnerTransformedIntegrationEvent({
    required super.id,
    required super.occurredOn,
    required super.tenantId,
    required super.partnerId,
  }) : super(eventType: type);

  static const String type = 'partner.partner.transformed';
}
