import 'package:c45_shared_application/application.dart';

import '../i_command_pipeline_behavior.dart';

final class TenantGuardCommandHandlerDecorator<TCommand extends ICommand<TResult>, TResult>
    implements ICommandPipelineBehavior<TCommand, TResult> {
  TenantGuardCommandHandlerDecorator({
    required ITenantAccessChecker tenantAccessChecker,
    required Future<TResult> Function(TCommand command) inner,
  }) : _tenantAccessChecker = tenantAccessChecker,
       _inner = inner;

  final ITenantAccessChecker _tenantAccessChecker;
  final Future<TResult> Function(TCommand command) _inner;

  @override
  Future<TResult> handle(
    TCommand command,
    Future<TResult> Function(TCommand command) next,
  ) async {
    if (command is ITenantScopedCommand) {
      await _tenantAccessChecker.ensureAccess(
        (command as ITenantScopedCommand).tenantId,
      );
    }
    return _inner(command);
  }

  Future<TResult> handleCommand(TCommand command) => handle(command, _inner);
}
