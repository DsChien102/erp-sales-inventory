import 'package:get_it/get_it.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../processing/generated/partner_cqrs_registrar.g.dart';
import '../processing/internal_commands/i_partner_internal_command_client.dart';

/// Registers partner command/query handlers via codegen.
final class PartnerMediationModule {
  const PartnerMediationModule();

  void load({
    required GetIt container,
    required CommandBus commandBus,
    required QueryBus queryBus,
    ILogger? commandLogger,
  }) {
    registerGeneratedPartnerHandlers(
      bus: commandBus,
      container: container,
      internalCommandClient: container.get<IPartnerInternalCommandClient>(),
      logger: commandLogger,
    );

    registerGeneratedPartnerQueries(
      bus: queryBus,
      container: container,
    );
  }
}
