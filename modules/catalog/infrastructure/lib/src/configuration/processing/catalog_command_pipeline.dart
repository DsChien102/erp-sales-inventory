import 'package:get_it/get_it.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'internal_commands/i_catalog_internal_command_client.dart';

/// Catalog business-command pipeline — injects access metadata and checkers.
abstract final class CatalogCommandPipeline {
  static CommandStep<TCommand, TResult>
  buildBusinessPipeline<TCommand extends ICommand<TResult>, TResult, THandler extends Object>({
    required GetIt container,
    required THandler handler,
    required Future<TResult> Function(TCommand command, THandler handler) invoke,
    ILogger? logger,
  }) {
    return DefaultCommandPipeline.buildBusinessPipeline<TCommand, TResult, THandler>(
      container: container,
      handler: handler,
      invoke: invoke,
      logger: logger,
      accessMetadata: container.get<IAccessMetadataRegistry>(),
      permissionChecker: container.get<IPermissionChecker>(),
      tenantAccessChecker: container.get<ITenantAccessChecker>(),
    );
  }

  static CommandStep<TCommand, void> buildInternalPipeline<
    TCommand extends InternalCommandBase<void>
  >({
    required GetIt container,
    required Future<void> Function(TCommand command) inner,
    required ICatalogInternalCommandClient commandClient,
    ILogger? logger,
  }) {
    return (command) => LoggingCommandHandlerDecorator<TCommand, void>(
      inner: inner,
      logger: logger,
    ).handle(command);
  }
}
