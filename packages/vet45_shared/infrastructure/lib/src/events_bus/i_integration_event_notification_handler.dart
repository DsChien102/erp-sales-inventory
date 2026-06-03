import 'integration_event.dart';

/// MediatR `INotificationHandler<IntegrationEvent>` equivalent for inbox processing.
abstract interface class IIntegrationEventNotificationHandler<T extends IntegrationEvent> {
  Future<void> handle(T event);
}
