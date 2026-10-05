import 'package:get_it/get_it.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../processing/generated/inventory_cqrs_registrar.g.dart';
import '../processing/internal_commands/i_inventory_internal_command_client.dart';

final class InventoryMediationModule {
  const InventoryMediationModule();

  void load({
    required GetIt container,
    required CommandBus commandBus,
    required QueryBus queryBus,
    ILogger? commandLogger,
  }) {
    registerGeneratedInventoryHandlers(
      bus: commandBus,
      container: container,
      internalCommandClient: container.get<IInventoryInternalCommandClient>(),
      logger: commandLogger,
    );
    registerGeneratedInventoryQueries(
      bus: queryBus,
      container: container,
    );
  }
}
