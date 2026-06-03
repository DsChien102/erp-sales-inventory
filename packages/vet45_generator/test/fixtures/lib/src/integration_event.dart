abstract class IntegrationEvent {
  const IntegrationEvent();
}

abstract interface class IIntegrationEventNotificationHandler<T> {
  Future<void> handle(T event);
}
