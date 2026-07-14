import 'partner_integration_event.dart';

final class PartnerSoftDeletedIntegrationEvent extends PartnerIntegrationEvent {
  const PartnerSoftDeletedIntegrationEvent({
    required super.id,
    required super.occurredOn,
    required super.tenantId,
    required super.partnerId,
    this.reason,
  }) : super(eventType: type);

  static const String type = 'partner.partner.soft_deleted';

  final String? reason;
}
