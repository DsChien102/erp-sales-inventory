import 'package:vet45_shared_infrastructure/infrastructure.dart';

/// Dispatches deserialized inbox integration events to application handlers.
final class EinvoiceIntegrationEventDispatcher {
  final Map<Type, Future<void> Function(TenantScopedIntegrationEvent event)>
  _handlers = {};

  void register<T extends TenantScopedIntegrationEvent>(
    IIntegrationEventNotificationHandler<T> handler,
  ) {
    _handlers[T] = (event) => handler.handle(event as T);
  }

  Future<void> publish(TenantScopedIntegrationEvent event) async {
    final handler = _handlers[event.runtimeType];
    if (handler == null) {
      throw StateError('No integration event handler for ${event.runtimeType}');
    }
    await handler(event);
  }
}
