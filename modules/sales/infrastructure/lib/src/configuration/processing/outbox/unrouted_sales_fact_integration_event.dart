import 'package:vet45_shared_infrastructure/infrastructure.dart';

/// Opaque Sales outbox fact without a typed subscriber in this runtime.
///
/// Completing via this type avoids poisoning the queue when Sales publishes
/// facts that the current worker does not deserialize as typed contracts yet.
final class UnroutedSalesFactIntegrationEvent extends TenantScopedIntegrationEvent {
  UnroutedSalesFactIntegrationEvent({
    required super.id,
    required super.occurredOn,
    required super.tenantId,
    required super.eventType,
    required Map<String, dynamic> payload,
  }) : _payload = Map<String, dynamic>.from(payload);

  final Map<String, dynamic> _payload;

  @override
  Map<String, dynamic> toPayload() => Map<String, dynamic>.from(_payload);
}
