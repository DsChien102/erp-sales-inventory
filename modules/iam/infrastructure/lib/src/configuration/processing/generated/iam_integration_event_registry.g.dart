// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:get_it/get_it.dart';
import 'package:quiver/collection.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';
import 'package:vet45_iam_integration_events/integration_events.dart';
import '../iam_integration_event_dispatcher.dart';
import '../../events_bus/iam_integration_event_generic_handler.dart';
import '../../outbox/outbox_module.dart';
import '../inbox/i_iam_inbox_client.dart';

/// Deserialize integration events from inbox/outbox payloads.
abstract final class IamIntegrationEventRegistry {
  static const eventTypes = <Type, String>{
    EmailDeliveryRequestedIntegrationEvent: EmailDeliveryRequestedIntegrationEvent.type,
    MembershipDeactivatedIntegrationEvent: MembershipDeactivatedIntegrationEvent.type,
  };

  static TenantScopedIntegrationEvent? fromJson({
    required String eventType,
    required Map<String, dynamic> payload,
  }) {
    if (eventType == EmailDeliveryRequestedIntegrationEvent.type) {
      return EmailDeliveryRequestedIntegrationEvent.fromPayload(payload);
    }
    if (eventType == MembershipDeactivatedIntegrationEvent.type) {
      return MembershipDeactivatedIntegrationEvent.fromPayload(payload);
    }
    return null;
  }
}

/// Deserializes outbox payloads into Iam integration events.
abstract final class IamOutboxEventSerializer {
  static TenantScopedIntegrationEvent fromPayload({
    required Type type,
    required Map<String, dynamic> payload,
  }) {
    if (type == EmailDeliveryRequestedIntegrationEvent) {
      return EmailDeliveryRequestedIntegrationEvent.fromPayload(payload);
    }
    if (type == MembershipDeactivatedIntegrationEvent) {
      return MembershipDeactivatedIntegrationEvent.fromPayload(payload);
    }
    throw StateError('Unsupported outbox event type: $type');
  }
}

OutboxModule createGeneratedIamOutboxModule() {
  final map = BiMap<String, Type>();
  map[EmailDeliveryRequestedIntegrationEvent.type] = EmailDeliveryRequestedIntegrationEvent;
  map[MembershipDeactivatedIntegrationEvent.type] = MembershipDeactivatedIntegrationEvent;
  return OutboxModule(map);
}

void registerGeneratedIamIntegrationEventSubscriptions({
  required IEventsBus eventBus,
  required IIamInboxClient inboxClient,
  required ILogger logger,
}) {
  IntegrationEventTypeRegistry.registerAll(IamIntegrationEventRegistry.eventTypes);
  logger.info('Subscribe to inbound iam.email.delivery_requested');
  eventBus.subscribe(
    IamIntegrationEventGenericHandler<EmailDeliveryRequestedIntegrationEvent>(inboxClient: inboxClient),
  );
  logger.info('Subscribe to inbound iam.membership.deactivated');
  eventBus.subscribe(
    IamIntegrationEventGenericHandler<MembershipDeactivatedIntegrationEvent>(inboxClient: inboxClient),
  );
}

IamIntegrationEventDispatcher createGeneratedIamIntegrationEventDispatcher(GetIt container) {
  final dispatcher = IamIntegrationEventDispatcher();
  dispatcher.register<EmailDeliveryRequestedIntegrationEvent>(
    EmailDeliveryRequestedIntegrationEventHandler(
      commandScheduler: container.get<ICommandScheduler>(),
    ),
  );
  dispatcher.register<MembershipDeactivatedIntegrationEvent>(
    MembershipDeactivatedIntegrationEventHandler(
      preferencePort: container.get<IPlatformUserPreferencePort>(),
    ),
  );
  return dispatcher;
}

