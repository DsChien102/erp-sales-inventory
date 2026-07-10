import 'partner_integration_event.dart';

final class PartnerContactChangedIntegrationEvent extends PartnerIntegrationEvent {
  const PartnerContactChangedIntegrationEvent({
    required super.id,
    required super.occurredOn,
    required super.tenantId,
    required super.partnerId,
    required this.changeType,
    this.personPartnerId,
  }) : super(eventType: type);

  static const String type = 'partner.partner.contact_changed';

  final String changeType;
  final String? personPartnerId;
}
