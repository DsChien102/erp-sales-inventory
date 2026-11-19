import 'package:get_it/get_it.dart';
import 'package:c45_shared_application/application.dart';

import '../logging/i_logger.dart';
import 'command_pipeline_builder.dart';
import 'decorators/authorization_command_handler_decorator.dart';
import 'decorators/logging_command_handler_decorator.dart';
import 'decorators/tenant_guard_command_handler_decorator.dart';
import 'decorators/validation_command_handler_decorator.dart';

/// Shared business-command pipeline: optional validation, then logging, then handler.
abstract final class DefaultCommandPipeline {
  static CommandStep<TCommand, TResult>
  buildBusinessPipeline<TCommand extends ICommand<TResult>, TResult, THandler extends Object>({
    required GetIt container,
    required THandler handler,
    required Future<TResult> Function(TCommand command, THandler handler) invoke,
    ILogger? logger,
    IAccessMetadataRegistry? accessMetadata,
    IPermissionChecker? permissionChecker,
    ITenantAccessChecker? tenantAccessChecker,
  }) {
    var builder = CommandPipelineBuilder<TCommand, TResult>(
      (command) => invoke(command, handler),
    );

    if (container.isRegistered<ICommandValidator<TCommand>>()) {
      final validator = container.get<ICommandValidator<TCommand>>();
      builder = builder.wrap(
        (command, next) => ValidationCommandHandlerDecorator(
          validator: validator,
          inner: next,
        ).handle(command),
      );
    }

    if (accessMetadata != null && permissionChecker != null) {
      builder = builder.wrap((command, next) async {
        final metadata = accessMetadata.forType(command.runtimeType);
        if (metadata?.permission != null) {
          return AuthorizationCommandHandlerDecorator<TCommand, TResult>(
            permissionChecker: permissionChecker,
            permissionCode: metadata!.permission!,
            inner: next,
          ).handleCommand(command);
        }
        return next(command);
      });
    }

    if (accessMetadata != null && tenantAccessChecker != null) {
      builder = builder.wrap((command, next) async {
        final metadata = accessMetadata.forType(command.runtimeType);
        if (metadata?.requiresTenant == true) {
          return TenantGuardCommandHandlerDecorator<TCommand, TResult>(
            tenantAccessChecker: tenantAccessChecker,
            inner: next,
          ).handleCommand(command);
        }
        return next(command);
      });
    }

    return builder
        .wrap(
          (command, next) => LoggingCommandHandlerDecorator(
            inner: next,
            logger: logger,
          ).handle(command),
        )
        .build();
  }
}
