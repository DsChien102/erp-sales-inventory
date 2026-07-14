import 'partner_integration_event.dart';

final class PartnerDeactivatedIntegrationEvent extends PartnerIntegrationEvent {
  const PartnerDeactivatedIntegrationEvent({
    required super.id,
    required super.occurredOn,
    required super.tenantId,
    required super.partnerId,
    this.reason,
  }) : super(eventType: type);

  static const String type = 'partner.partner.deactivated';

  final String? reason;
}
