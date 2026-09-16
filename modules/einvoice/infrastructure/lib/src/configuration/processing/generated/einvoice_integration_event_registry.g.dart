// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:get_it/get_it.dart';
import 'package:quiver/collection.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';
import 'package:vet45_einvoice_integration_events/integration_events.dart';
import 'package:vet45_partner_integration_events/integration_events.dart';
import 'package:vet45_sales_integration_events/integration_events.dart';
import '../einvoice_integration_event_dispatcher.dart';
import '../../events_bus/einvoice_integration_event_generic_handler.dart';
import '../../outbox/outbox_module.dart';
import '../inbox/i_einvoice_inbox_client.dart';

/// Deserialize integration events from inbox/outbox payloads.
abstract final class EinvoiceIntegrationEventRegistry {
  static const eventTypes = <Type, String>{
    DeliveryAttentionRequiredIntegrationEvent:
        DeliveryAttentionRequiredIntegrationEvent.type,
    DeliveryResultRecordedIntegrationEvent:
        DeliveryResultRecordedIntegrationEvent.type,
    ElectronicInvoiceRegisteredIntegrationEvent:
        ElectronicInvoiceRegisteredIntegrationEvent.type,
    ProviderIssuanceResultReceivedIntegrationEvent:
        ProviderIssuanceResultReceivedIntegrationEvent.type,
    ProviderObservationAttentionRequiredIntegrationEvent:
        ProviderObservationAttentionRequiredIntegrationEvent.type,
    PartnerProfileUpdatedIntegrationEvent:
        PartnerProfileUpdatedIntegrationEvent.type,
    SalesOrderFinalizedIntegrationEvent:
        SalesOrderFinalizedIntegrationEvent.type,
  };

  static TenantScopedIntegrationEvent? fromJson({
    required String eventType,
    required Map<String, dynamic> payload,
  }) {
    if (eventType == DeliveryAttentionRequiredIntegrationEvent.type) {
      return DeliveryAttentionRequiredIntegrationEvent.fromPayload(payload);
    }
    if (eventType == DeliveryResultRecordedIntegrationEvent.type) {
      return DeliveryResultRecordedIntegrationEvent.fromPayload(payload);
    }
    if (eventType == ElectronicInvoiceRegisteredIntegrationEvent.type) {
      return ElectronicInvoiceRegisteredIntegrationEvent.fromPayload(payload);
    }
    if (eventType == ProviderIssuanceResultReceivedIntegrationEvent.type) {
      return ProviderIssuanceResultReceivedIntegrationEvent.fromPayload(
        payload,
      );
    }
    if (eventType ==
        ProviderObservationAttentionRequiredIntegrationEvent.type) {
      return ProviderObservationAttentionRequiredIntegrationEvent.fromPayload(
        payload,
      );
    }
    if (eventType == PartnerProfileUpdatedIntegrationEvent.type) {
      return PartnerProfileUpdatedIntegrationEvent.fromPayload(payload);
    }
    if (eventType == SalesOrderFinalizedIntegrationEvent.type) {
      return SalesOrderFinalizedIntegrationEvent.fromPayload(payload);
    }
    return null;
  }
}

/// Deserializes outbox payloads into Einvoice integration events.
abstract final class EinvoiceOutboxEventSerializer {
  static TenantScopedIntegrationEvent fromPayload({
    required Type type,
    required Map<String, dynamic> payload,
  }) {
    if (type == DeliveryAttentionRequiredIntegrationEvent) {
      return DeliveryAttentionRequiredIntegrationEvent.fromPayload(payload);
    }
    if (type == DeliveryResultRecordedIntegrationEvent) {
      return DeliveryResultRecordedIntegrationEvent.fromPayload(payload);
    }
    if (type == ElectronicInvoiceRegisteredIntegrationEvent) {
      return ElectronicInvoiceRegisteredIntegrationEvent.fromPayload(payload);
    }
    if (type == ProviderIssuanceResultReceivedIntegrationEvent) {
      return ProviderIssuanceResultReceivedIntegrationEvent.fromPayload(
        payload,
      );
    }
    if (type == ProviderObservationAttentionRequiredIntegrationEvent) {
      return ProviderObservationAttentionRequiredIntegrationEvent.fromPayload(
        payload,
      );
    }
    if (type == PartnerProfileUpdatedIntegrationEvent) {
      return PartnerProfileUpdatedIntegrationEvent.fromPayload(payload);
    }
    if (type == SalesOrderFinalizedIntegrationEvent) {
      return SalesOrderFinalizedIntegrationEvent.fromPayload(payload);
    }
    throw StateError('Unsupported outbox event type: $type');
  }
}

OutboxModule createGeneratedEinvoiceOutboxModule() {
  final map = BiMap<String, Type>();
  map[DeliveryAttentionRequiredIntegrationEvent.type] =
      DeliveryAttentionRequiredIntegrationEvent;
  map[DeliveryResultRecordedIntegrationEvent.type] =
      DeliveryResultRecordedIntegrationEvent;
  map[ElectronicInvoiceRegisteredIntegrationEvent.type] =
      ElectronicInvoiceRegisteredIntegrationEvent;
  map[ProviderIssuanceResultReceivedIntegrationEvent.type] =
      ProviderIssuanceResultReceivedIntegrationEvent;
  map[ProviderObservationAttentionRequiredIntegrationEvent.type] =
      ProviderObservationAttentionRequiredIntegrationEvent;
  map[PartnerProfileUpdatedIntegrationEvent.type] =
      PartnerProfileUpdatedIntegrationEvent;
  map[SalesOrderFinalizedIntegrationEvent.type] =
      SalesOrderFinalizedIntegrationEvent;
  return OutboxModule(map);
}

void registerGeneratedEinvoiceIntegrationEventSubscriptions({
  required IEventsBus eventBus,
  required IEinvoiceInboxClient inboxClient,
  required ILogger logger,
}) {
  IntegrationEventTypeRegistry.registerAll(
    EinvoiceIntegrationEventRegistry.eventTypes,
  );
  logger.info('Subscribe to inbound einvoice.delivery.attention_required');
  eventBus.subscribe(
    EinvoiceIntegrationEventGenericHandler<
      DeliveryAttentionRequiredIntegrationEvent
    >(inboxClient: inboxClient),
  );
  logger.info('Subscribe to inbound einvoice.delivery.result_recorded');
  eventBus.subscribe(
    EinvoiceIntegrationEventGenericHandler<
      DeliveryResultRecordedIntegrationEvent
    >(inboxClient: inboxClient),
  );
  logger.info('Subscribe to inbound einvoice.electronic_invoice.registered');
  eventBus.subscribe(
    EinvoiceIntegrationEventGenericHandler<
      ElectronicInvoiceRegisteredIntegrationEvent
    >(inboxClient: inboxClient),
  );
  logger.info(
    'Subscribe to inbound einvoice.provider.issuance_result_received',
  );
  eventBus.subscribe(
    EinvoiceIntegrationEventGenericHandler<
      ProviderIssuanceResultReceivedIntegrationEvent
    >(inboxClient: inboxClient),
  );
  logger.info(
    'Subscribe to inbound einvoice.provider_observation_attention_required',
  );
  eventBus.subscribe(
    EinvoiceIntegrationEventGenericHandler<
      ProviderObservationAttentionRequiredIntegrationEvent
    >(inboxClient: inboxClient),
  );
  logger.info('Subscribe to inbound partner.partner.profile_updated');
  eventBus.subscribe(
    EinvoiceIntegrationEventGenericHandler<
      PartnerProfileUpdatedIntegrationEvent
    >(inboxClient: inboxClient),
  );
  logger.info('Subscribe to inbound sales_order_finalized.v1');
  eventBus.subscribe(
    EinvoiceIntegrationEventGenericHandler<SalesOrderFinalizedIntegrationEvent>(
      inboxClient: inboxClient,
    ),
  );
}

EinvoiceIntegrationEventDispatcher
createGeneratedEinvoiceIntegrationEventDispatcher(GetIt container) {
  final dispatcher = EinvoiceIntegrationEventDispatcher();
  dispatcher.register<ElectronicInvoiceRegisteredIntegrationEvent>(
    ElectronicInvoiceRegisteredIntegrationEventHandler(
      commands: container.get<IEinvoiceCommandDispatcher>(),
    ),
  );
  dispatcher.register<PartnerProfileUpdatedIntegrationEvent>(
    PartnerProfileUpdatedIntegrationEventHandler(
      gateway: container.get<IAutoIssuanceGateway>(),
      commands: container.get<IEinvoiceCommandDispatcher>(),
    ),
  );
  dispatcher.register<ProviderIssuanceResultReceivedIntegrationEvent>(
    ProviderIssuanceResultReceivedIntegrationEventHandler(
      commands: container.get<IEinvoiceCommandDispatcher>(),
    ),
  );
  dispatcher.register<SalesOrderFinalizedIntegrationEvent>(
    SalesOrderFinalizedIntegrationEventHandler(
      commands: container.get<IEinvoiceCommandDispatcher>(),
    ),
  );
  return dispatcher;
}
