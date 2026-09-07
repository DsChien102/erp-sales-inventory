import 'package:get_it/get_it.dart';
import 'package:quiver/collection.dart';
import 'package:vet45_einvoice_integration_events/integration_events.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../processing/generated/einvoice_integration_event_registry.g.dart';

/// Maps outbox `event_type` strings to integration event [Type]s.
final class OutboxModule {
  OutboxModule(this._eventTypeMap);

  final BiMap<String, Type> _eventTypeMap;

  /// Generated delivery/issuance/partner/sales types plus legacy S1/S2b events
  /// that ProcessOutbox still deserializes.
  static OutboxModule createDefault() {
    final map = BiMap<String, Type>();
    map[ConfigurationReadinessChangedIntegrationEvent.type] =
        ConfigurationReadinessChangedIntegrationEvent;
    map[IssuanceProcessingIntegrationEvent.type] =
        IssuanceProcessingIntegrationEvent;
    map[IssuanceFailedIntegrationEvent.type] = IssuanceFailedIntegrationEvent;

    final generated = createGeneratedEinvoiceOutboxModule();
    for (final entry in generated._eventTypeMap.entries) {
      map[entry.key] = entry.value;
    }
    return OutboxModule(map);
  }

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
