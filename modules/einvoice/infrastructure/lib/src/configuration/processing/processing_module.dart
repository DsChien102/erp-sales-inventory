import 'package:get_it/get_it.dart';
import 'package:quiver/collection.dart';
import 'package:vet45_adapters/vet45_adapters.dart'
    hide InternalCommandSerializer, ISerializableInternalCommand;
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_integration_events/integration_events.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'einvoice_command_dispatcher.dart';
import 'einvoice_integration_event_dispatcher.dart';
import 'generated/einvoice_integration_event_registry.g.dart';
import 'generated/einvoice_internal_command_registry.g.dart';
import 'inbox/i_einvoice_inbox_client.dart';
import 'inbox/process_inbox_command.dart';
import 'inbox/process_inbox_command_handler.dart';
import 'inbox/supabase_einvoice_inbox_client.dart';
import 'internal_commands/delivery_command_dead_letter_handler.dart';
import 'internal_commands/delivery_reconciliation_command_dead_letter_handler.dart';
import 'internal_commands/i_einvoice_internal_command_dead_letter_handler.dart';
import 'internal_commands/invoice_document_command_dead_letter_handler.dart';
import 'internal_commands/official_view_command_dead_letter_handler.dart';
import 'internal_commands/preview_command_dead_letter_handler.dart';
import 'internal_commands/process_internal_commands_command.dart';
import 'internal_commands/process_internal_commands_command_handler.dart';
import 'internal_commands/publish_invoice_command_dead_letter_handler.dart';
import 'internal_commands/supabase_einvoice_internal_command_client.dart';
import 'outbox/i_einvoice_outbox_client.dart';
import 'outbox/process_outbox_command.dart';
import 'outbox/process_outbox_command_handler.dart';
import 'outbox/supabase_einvoice_outbox_client.dart';

/// Wires outbox / inbox / internal-command clients and Process* handlers.
final class EinvoiceProcessingModule {
  const EinvoiceProcessingModule();

  void load({
    required GetIt container,
    required SupabaseSchemaRpcClient rpcClient,
    required IEventsBus eventsBus,
    required IDomainNotificationMapper eventTypeMapper,
  }) {
    final serializer = createGeneratedEinvoiceInternalCommandSerializer();
    final outboxClient = SupabaseEinvoiceOutboxClient(rpcClient: rpcClient);
    final inboxClient = SupabaseEinvoiceInboxClient(rpcClient: rpcClient);
    final internalCommandClient = SupabaseEinvoiceInternalCommandClient(
      rpcClient: rpcClient,
    );

    if (container.isRegistered<CommandBus>() &&
        !container.isRegistered<IEinvoiceCommandDispatcher>()) {
      container.registerSingleton<IEinvoiceCommandDispatcher>(
        EinvoiceCommandDispatcher(commandBus: container.get<CommandBus>()),
      );
    }

    final integrationEventDispatcher =
        container.isRegistered<EinvoiceIntegrationEventDispatcher>()
        ? container.get<EinvoiceIntegrationEventDispatcher>()
        : (container.isRegistered<IAutoIssuanceGateway>() &&
                  container.isRegistered<IEinvoiceCommandDispatcher>()
              ? createGeneratedEinvoiceIntegrationEventDispatcher(container)
              : EinvoiceIntegrationEventDispatcher());

    final processOutboxHandler = ProcessOutboxCommandHandler(
      outboxClient: outboxClient,
      eventTypeMapper: eventTypeMapper,
      eventsBus: eventsBus,
    );
    final processInboxHandler = ProcessInboxCommandHandler(
      inboxClient: inboxClient,
      integrationEventDispatcher: integrationEventDispatcher,
    );
    final deadLetterHandlers =
        <String, IEinvoiceInternalCommandDeadLetterHandler>{
          if (container.isRegistered<IIssuanceResultGateway>())
            PublishInvoiceCommand.type: PublishInvoiceCommandDeadLetterHandler(
              resultGateway: container.get<IIssuanceResultGateway>(),
            ),
          if (container.isRegistered<IInvoicePreviewGateway>())
            PreviewInvoiceCommand.type: PreviewCommandDeadLetterHandler(
              previewGateway: container.get<IInvoicePreviewGateway>(),
            ),
          if (container.isRegistered<IElectronicInvoiceCommandGateway>()) ...{
            FetchOfficialInvoiceViewCommand
                .type: OfficialViewCommandDeadLetterHandler(
              commandGateway: container.get<IElectronicInvoiceCommandGateway>(),
            ),
            DownloadInvoiceDocumentCommand
                .type: InvoiceDocumentCommandDeadLetterHandler(
              commandGateway: container.get<IElectronicInvoiceCommandGateway>(),
            ),
          },
          if (container.isRegistered<IDeliveryCommandGateway>())
            SendInvoiceEmailCommand.type: DeliveryCommandDeadLetterHandler(
              commandGateway: container.get<IDeliveryCommandGateway>(),
            ),
          if (container.isRegistered<IDeliveryReconciliationGateway>())
            ReconcileInvoiceDeliveryCommand.type:
                DeliveryReconciliationCommandDeadLetterHandler(
                  reconciliationGateway: container
                      .get<IDeliveryReconciliationGateway>(),
                ),
        };
    final processInternalHandler = ProcessInternalCommandsCommandHandler(
      commandClient: internalCommandClient,
      serializer: serializer,
      deadLetterHandlers: deadLetterHandlers,
    );

    container
      ..registerSingleton<InternalCommandSerializer>(serializer)
      ..registerSingleton<IEinvoiceOutboxClient>(outboxClient)
      ..registerSingleton<IEinvoiceInboxClient>(inboxClient)
      ..registerSingleton<IEinvoiceInternalCommandClient>(internalCommandClient)
      ..registerSingleton(integrationEventDispatcher)
      ..registerSingleton(processOutboxHandler)
      ..registerSingleton(processInboxHandler)
      ..registerSingleton(processInternalHandler);
  }

  void registerProcessHandlers({
    required CommandBus commandBus,
    required GetIt container,
  }) {
    commandBus.register<ProcessOutboxCommand, bool>(
      (command) => container.get<ProcessOutboxCommandHandler>().handle(command),
    );
    commandBus.register<ProcessInboxCommand, bool>(
      (command) => container.get<ProcessInboxCommandHandler>().handle(command),
    );
    commandBus.register<ProcessInternalCommandsCommand, bool>(
      (command) => container
          .get<ProcessInternalCommandsCommandHandler>()
          .handle(command),
    );
  }
}

/// Maps outbox event_type strings to integration event [Type]s.
///
/// Prefer [OutboxModule.createDefault] for startup. Kept for S2b tests that
/// assert issuance processing/failed mappings alongside registered.
final class EinvoiceOutboxModule {
  EinvoiceOutboxModule(this._eventTypeMap);

  final BiMap<String, Type> _eventTypeMap;

  static EinvoiceOutboxModule createDefault() {
    final map = BiMap<String, Type>();
    map[ConfigurationReadinessChangedIntegrationEvent.type] =
        ConfigurationReadinessChangedIntegrationEvent;
    map[IssuanceProcessingIntegrationEvent.type] =
        IssuanceProcessingIntegrationEvent;
    map[IssuanceFailedIntegrationEvent.type] = IssuanceFailedIntegrationEvent;
    map[ElectronicInvoiceRegisteredIntegrationEvent.type] =
        ElectronicInvoiceRegisteredIntegrationEvent;
    map[DeliveryResultRecordedIntegrationEvent.type] =
        DeliveryResultRecordedIntegrationEvent;
    map[DeliveryAttentionRequiredIntegrationEvent.type] =
        DeliveryAttentionRequiredIntegrationEvent;
    map[ProviderIssuanceResultReceivedIntegrationEvent.type] =
        ProviderIssuanceResultReceivedIntegrationEvent;
    map[ProviderObservationAttentionRequiredIntegrationEvent.type] =
        ProviderObservationAttentionRequiredIntegrationEvent;
    return EinvoiceOutboxModule(map);
  }

  IDomainNotificationMapper get mapper =>
      DomainNotificationMapper(_eventTypeMap);

  void load(GetIt container) {
    container.registerSingleton<IDomainNotificationMapper>(mapper);
  }
}
