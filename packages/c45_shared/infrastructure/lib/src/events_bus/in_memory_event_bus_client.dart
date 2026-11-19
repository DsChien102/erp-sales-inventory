import 'i_integration_event_handler.dart';
import 'i_events_bus.dart';
import 'integration_event.dart';
import 'integration_event_bus.dart';

/// ERP-wide integration bus backed by [IntegrationEventBus].
final class InMemoryEventBusClient implements IEventsBus {
  InMemoryEventBusClient();

  final IntegrationEventBus _bus = IntegrationEventBus();

  @override
  void subscribe<T extends IntegrationEvent>(IIntegrationEventHandler<T> handler) {
    _bus.subscribe(handler);
  }

  @override
  Future<void> publish(IntegrationEvent event) {
    return _bus.publish(event);
  }
}
