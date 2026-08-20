import 'package:get_it/get_it.dart';
import 'package:quiver/collection.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../processing/generated/iam_integration_event_registry.g.dart';

/// Maps outbox `event_type` strings to integration event [Type]s.
final class OutboxModule {
  OutboxModule(this._eventTypeMap);

  final BiMap<String, Type> _eventTypeMap;

  static OutboxModule createDefault() => createGeneratedIamOutboxModule();

  IDomainNotificationMapper get mapper =>
      DomainNotificationMapper(_eventTypeMap);

  void load(GetIt container) {
    checkMappings();
    container.registerSingleton<IDomainNotificationMapper>(mapper);
  }

  void checkMappings() {
    if (_eventTypeMap.isEmpty) {
      throw StateError('Outbox events not mapped');
    }
  }
}
