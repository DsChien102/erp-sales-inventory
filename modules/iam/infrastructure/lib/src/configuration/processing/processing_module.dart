import 'package:get_it/get_it.dart';
import 'package:vet45_adapters/vet45_adapters.dart'
    hide InternalCommandSerializer, ISerializableInternalCommand;
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'generated/iam_integration_event_registry.g.dart';
import 'generated/iam_internal_command_registry.g.dart';
import 'inbox/i_iam_inbox_client.dart';
import 'inbox/process_inbox_command.dart';
import 'inbox/process_inbox_command_handler.dart';
import 'inbox/supabase_iam_inbox_client.dart';
import 'internal_commands/process_internal_commands_command.dart';
import 'internal_commands/process_internal_commands_command_handler.dart';
import 'internal_commands/supabase_iam_command_scheduler.dart';
import 'internal_commands/supabase_iam_internal_command_client.dart';
import 'outbox/i_iam_outbox_client.dart';
import 'outbox/process_outbox_command.dart';
import 'outbox/process_outbox_command_handler.dart';
import 'outbox/supabase_iam_outbox_client.dart';

/// Wires outbox / inbox / internal-command clients and Process* handlers.
final class ProcessingModule {
  const ProcessingModule();

  void load({
    required GetIt container,
    required SupabaseSchemaRpcClient rpcClient,
  }) {
    final serializer = createGeneratedIamInternalCommandSerializer();
    final outboxClient = SupabaseIamOutboxClient(rpcClient: rpcClient);
    final inboxClient = SupabaseIamInboxClient(rpcClient: rpcClient);
    final internalCommandClient = SupabaseIamInternalCommandClient(
      rpcClient: rpcClient,
    );
    final commandScheduler = SupabaseIamCommandScheduler(
      rpcClient: rpcClient,
      serializer: serializer,
    );

    // Generated dispatcher resolves handler deps from GetIt eagerly.
    container
      ..registerSingleton<InternalCommandSerializer>(serializer)
      ..registerSingleton<IIamOutboxClient>(outboxClient)
      ..registerSingleton<IIamInboxClient>(inboxClient)
      ..registerSingleton<IIamInternalCommandClient>(internalCommandClient)
      ..registerSingleton<ICommandScheduler>(commandScheduler);

    final integrationEventDispatcher =
        createGeneratedIamIntegrationEventDispatcher(container);

    final processOutboxHandler = ProcessOutboxCommandHandler(
      outboxClient: outboxClient,
      eventTypeMapper: container.get<IDomainNotificationMapper>(),
      eventsBus: container.get<IEventsBus>(),
    );
    final processInboxHandler = ProcessInboxCommandHandler(
      inboxClient: inboxClient,
      integrationEventDispatcher: integrationEventDispatcher,
    );
    final processInternalHandler = ProcessInternalCommandsCommandHandler(
      commandClient: internalCommandClient,
      serializer: serializer,
    );

    container
      ..registerSingleton(integrationEventDispatcher)
      ..registerSingleton(processOutboxHandler)
      ..registerSingleton(processInboxHandler)
      ..registerSingleton(processInternalHandler);
  }

  /// Registers Process* commands on the [CommandBus].
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
      (command) =>
          container.get<ProcessInternalCommandsCommandHandler>().handle(command),
    );
  }
}
