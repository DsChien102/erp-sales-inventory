import 'partner_integration_event.dart';

/// Published when a partner is created.
final class PartnerCreatedIntegrationEvent extends PartnerIntegrationEvent {
  const PartnerCreatedIntegrationEvent({
    required super.id,
    required super.occurredOn,
    required super.tenantId,
    required super.partnerId,
    required this.partnerType,
    required this.displayName,
  }) : super(eventType: type);

  static const String type = 'partner.partner.created';

  final String partnerType;
  final String displayName;
}
