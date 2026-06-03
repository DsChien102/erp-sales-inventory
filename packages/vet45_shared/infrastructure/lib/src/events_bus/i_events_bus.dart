import 'i_integration_event_handler.dart';
import 'integration_event.dart';

/// Cross-module integration event bus contract.
abstract interface class IEventsBus {
  void subscribe<T extends IntegrationEvent>(IIntegrationEventHandler<T> handler);

  Future<void> publish(IntegrationEvent event);
}