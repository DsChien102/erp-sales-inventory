import 'package:get_it/get_it.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'outbox/i_sales_outbox_client.dart';
import 'outbox/process_outbox_command.dart';
import 'outbox/process_outbox_command_handler.dart';
import 'outbox/supabase_sales_outbox_client.dart';

/// Wires Sales outbox client and ProcessOutbox handler.
final class ProcessingModule {
  const ProcessingModule();

  void load({
    required GetIt container,
    required SupabaseSchemaRpcClient rpcClient,
    ISalesOutboxClient? outboxClient,
  }) {
    final resolvedOutbox = outboxClient ?? SupabaseSalesOutboxClient(rpcClient: rpcClient);
    final processOutboxHandler = ProcessOutboxCommandHandler(
      outboxClient: resolvedOutbox,
      eventsBus: container.get<IEventsBus>(),
    );

    container
      ..registerSingleton<ISalesOutboxClient>(resolvedOutbox)
      ..registerSingleton(processOutboxHandler);
  }

  /// Registers Process* commands on the [CommandBus].
  void registerProcessHandlers({
    required CommandBus commandBus,
    required GetIt container,
  }) {
    commandBus.register<ProcessOutboxCommand, bool>(
      (command) => container.get<ProcessOutboxCommandHandler>().handle(command),
    );
  }
}
