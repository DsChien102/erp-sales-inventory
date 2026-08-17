import 'einvoice_integration_event.dart';

/// Published when configuration readiness level changes.
final class ConfigurationReadinessChangedIntegrationEvent
    extends EInvoiceIntegrationEvent {
  const ConfigurationReadinessChangedIntegrationEvent({
    required super.id,
    required super.occurredOn,
    required super.tenantId,
    required this.level,
  }) : super(eventType: type);

  static const String type = 'einvoice.configuration.readiness_changed';

  final String level;
}
