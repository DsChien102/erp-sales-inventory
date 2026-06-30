import 'package:get_it/get_it.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../processing/internal_commands/i_iam_internal_command_client.dart';
import '../processing/generated/iam_cqrs_registrar.g.dart';

/// Registers IAM command/query handlers via codegen.
final class IamMediationModule {
  const IamMediationModule();

  void load({
    required GetIt container,
    required CommandBus commandBus,
    required QueryBus queryBus,
    ILogger? commandLogger,
  }) {
    registerGeneratedIamHandlers(
      bus: commandBus,
      container: container,
      internalCommandClient: container.get<IIamInternalCommandClient>(),
      logger: commandLogger,
    );

    registerGeneratedIamQueries(
      bus: queryBus,
      container: container,
    );
  }
}
