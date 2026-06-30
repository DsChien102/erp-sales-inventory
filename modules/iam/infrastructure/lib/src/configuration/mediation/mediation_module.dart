import 'package:get_it/get_it.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../access/iam_access_metadata_registry.dart';

/// Registers IAM command/query handlers on shared buses.
final class IamMediationModule {
  const IamMediationModule();

  void load({
    required GetIt container,
    required CommandBus commandBus,
    required QueryBus queryBus,
    ILogger? commandLogger,
  }) {
    final accessMetadata = iamAccessMetadataRegistry;
    final permissionChecker = container.get<IPermissionChecker>();
    final tenantAccessChecker = container.get<ITenantAccessChecker>();

    commandBus
      ..register<SignInCommand, void>(
        DefaultCommandPipeline.buildBusinessPipeline<
          SignInCommand,
          void,
          SignInCommandHandler
        >(
          container: container,
          handler: container.get<SignInCommandHandler>(),
          invoke: (command, handler) => handler.handle(command),
          accessMetadata: accessMetadata,
          permissionChecker: permissionChecker,
          tenantAccessChecker: tenantAccessChecker,
          logger: commandLogger,
        ),
      )
      ..register<SignOutCommand, void>(
        DefaultCommandPipeline.buildBusinessPipeline<
          SignOutCommand,
          void,
          SignOutCommandHandler
        >(
          container: container,
          handler: container.get<SignOutCommandHandler>(),
          invoke: (command, handler) => handler.handle(command),
          accessMetadata: accessMetadata,
          permissionChecker: permissionChecker,
          tenantAccessChecker: tenantAccessChecker,
          logger: commandLogger,
        ),
      );

    queryBus.register<GetCurrentSessionQuery, SessionDto>(
      (query) => container.get<GetCurrentSessionQueryHandler>().handle(query),
    );
  }
}
