import 'i_integration_event_handler.dart';
import 'integration_event.dart';
import 'integration_event_type_registry.dart';

/// Typed integration event bus for module integration routing.
final class IntegrationEventBus {
  final Map<String, List<Future<void> Function(IntegrationEvent event)>> _handlers = {};

  void subscribe<T extends IntegrationEvent>(IIntegrationEventHandler<T> handler) {
    final eventType = IntegrationEventTypeRegistry.typeOf(T);
    _handlers.putIfAbsent(eventType, () => []).add(
      (event) => handler.handle(event as T),
    );
  }

  Future<void> publish(IntegrationEvent event) async {
    final handlers = _handlers[event.eventType];
    if (handlers == null || handlers.isEmpty) {
      return;
    }

    for (final handler in handlers) {
      await handler(event);
    }
  }

  void clear() => _handlers.clear();
}
