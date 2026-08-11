import 'package:get_it/get_it.dart';
import 'package:quiver/collection.dart';
import 'package:vet45_iam_integration_events/integration_events.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

/// Maps outbox `event_type` strings to integration event [Type]s.
final class OutboxModule {
  OutboxModule(this._eventTypeMap);

  final BiMap<String, Type> _eventTypeMap;

  static OutboxModule createDefault() {
    final map = BiMap<String, Type>();
    map[EmailDeliveryRequestedIntegrationEvent.type] =
        EmailDeliveryRequestedIntegrationEvent;
    return OutboxModule(map);
  }

  IDomainNotificationMapper get mapper =>
      DomainNotificationMapper(_eventTypeMap);

  void load(GetIt container) {
    checkMappings();
    container.registerSingleton<IDomainNotificationMapper>(mapper);
  }

  void checkMappings() {
    final required = <Type>[EmailDeliveryRequestedIntegrationEvent];
    final missing = <Type>[];
    for (final eventType in required) {
      if (_eventTypeMap.inverse[eventType] == null) {
        missing.add(eventType);
      }
    }
    if (missing.isNotEmpty) {
      throw StateError('Outbox events not mapped: $missing');
    }
  }
}
