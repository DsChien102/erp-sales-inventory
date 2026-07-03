import 'package:get_it/get_it.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'internal_commands/i_partner_internal_command_client.dart';
import 'internal_commands/internal_command_completion_decorator.dart';

/// Partner business-command pipeline — injects access metadata and checkers from container.
abstract final class PartnerCommandPipeline {
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
    required IPartnerInternalCommandClient commandClient,
    ILogger? logger,
  }) {
    var builder = CommandPipelineBuilder<TCommand, void>(inner);

    if (container.isRegistered<ICommandValidator<TCommand>>()) {
      final validator = container.get<ICommandValidator<TCommand>>();
      builder = builder.wrap(
        (command, next) => ValidationCommandHandlerDecorator(
          validator: validator,
          inner: next,
        ).handle(command),
      );
    }

    return builder
        .wrap(
          (command, next) => LoggingCommandHandlerDecorator(
            inner: next,
            logger: logger,
          ).handle(command),
        )
        .wrap(
          (command, next) => InternalCommandCompletionDecorator(
            inner: next,
            commandClient: commandClient,
          ).handle(command),
        )
        .build();
  }
}
