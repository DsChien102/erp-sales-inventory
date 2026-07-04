import 'package:get_it/get_it.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../processing/generated/catalog_cqrs_registrar.g.dart';
import '../processing/internal_commands/i_catalog_internal_command_client.dart';

/// Registers catalog command/query handlers via codegen.
final class CatalogMediationModule {
  const CatalogMediationModule();

  void load({
    required GetIt container,
    required CommandBus commandBus,
    required QueryBus queryBus,
    ILogger? commandLogger,
  }) {
    registerGeneratedCatalogHandlers(
      bus: commandBus,
      container: container,
      internalCommandClient: container.get<ICatalogInternalCommandClient>(),
      logger: commandLogger,
    );

    registerGeneratedCatalogQueries(
      bus: queryBus,
      container: container,
    );
  }
}
