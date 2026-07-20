import 'package:get_it/get_it.dart';
import 'package:vet45_iam_integration_events/integration_events.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../processing/inbox/i_iam_inbox_client.dart';
import '../processing/inbox/process_inbox_command_handler.dart';
import 'iam_integration_event_generic_handler.dart';

/// Subscribes IAM self-consume handlers on the shared [IEventsBus].
abstract final class EventsBusStartup {
  static void initialize(GetIt container, ILogger logger) {
    IntegrationEventTypeRegistry.registerAll(
      IamIntegrationEventRegistry.eventTypes,
    );
    _subscribeToIntegrationEvents(container, logger);
  }

  static void _subscribeToIntegrationEvents(GetIt container, ILogger logger) {
    final eventBus = container.get<IEventsBus>();
    final inboxClient = container.get<IIamInboxClient>();

    _subscribeToIntegrationEvent<EmailDeliveryRequestedIntegrationEvent>(
      eventBus: eventBus,
      inboxClient: inboxClient,
      logger: logger,
      eventType: EmailDeliveryRequestedIntegrationEvent.type,
    );
  }

  static void _subscribeToIntegrationEvent<
    T extends TenantScopedIntegrationEvent
  >({
    required IEventsBus eventBus,
    required IIamInboxClient inboxClient,
    required ILogger logger,
    required String eventType,
  }) {
    logger.info('Subscribe to inbound $eventType');
    eventBus.subscribe(
      IamIntegrationEventGenericHandler<T>(inboxClient: inboxClient),
    );
  }
}
