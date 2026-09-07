import 'package:get_it/get_it.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../processing/generated/einvoice_cqrs_registrar.g.dart';
import '../processing/internal_commands/i_einvoice_internal_command_client.dart';

final class EinvoiceMediationModule {
  const EinvoiceMediationModule();

  void load({
    required GetIt container,
    required CommandBus commandBus,
    required QueryBus queryBus,
    ILogger? commandLogger,
  }) {
    registerGeneratedEinvoiceHandlers(
      bus: commandBus,
      container: container,
      internalCommandClient: container.get<IEinvoiceInternalCommandClient>(),
      logger: commandLogger,
    );

    registerGeneratedEinvoiceQueries(bus: queryBus, container: container);
  }
}
