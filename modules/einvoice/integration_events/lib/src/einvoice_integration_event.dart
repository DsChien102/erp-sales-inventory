import 'package:vet45_shared_infrastructure/infrastructure.dart';

/// Base fields for einvoice publish integration events.
abstract base class EInvoiceIntegrationEvent extends IntegrationEvent {
  const EInvoiceIntegrationEvent({
    required super.id,
    required super.occurredOn,
    required super.eventType,
    required this.tenantId,
  });

  final String tenantId;
}
