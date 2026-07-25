import 'package:get_it/get_it.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../processing/generated/pricing_cqrs_registrar.g.dart';
import '../processing/internal_commands/i_pricing_internal_command_client.dart';

final class PricingMediationModule {
  const PricingMediationModule();

  void load({
    required GetIt container,
    required CommandBus commandBus,
    required QueryBus queryBus,
    ILogger? commandLogger,
  }) {
    registerGeneratedPricingHandlers(
      bus: commandBus,
      container: container,
      internalCommandClient: container.get<IPricingInternalCommandClient>(),
      logger: commandLogger,
    );
    registerGeneratedPricingQueries(bus: queryBus, container: container);
  }
}
