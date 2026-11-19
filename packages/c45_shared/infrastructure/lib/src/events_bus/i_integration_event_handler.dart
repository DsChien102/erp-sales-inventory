import 'integration_event.dart';

abstract interface class IIntegrationEventHandler<TIntegrationEvent extends IntegrationEvent> {
  Future<void> handle(TIntegrationEvent event);
}
