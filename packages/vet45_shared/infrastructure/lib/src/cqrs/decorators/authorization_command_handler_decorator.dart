import 'package:vet45_shared_application/application.dart';

import '../i_command_pipeline_behavior.dart';

final class AuthorizationCommandHandlerDecorator<TCommand extends ICommand<TResult>, TResult>
    implements ICommandPipelineBehavior<TCommand, TResult> {
  AuthorizationCommandHandlerDecorator({
    required IPermissionChecker permissionChecker,
    required String permissionCode,
    required Future<TResult> Function(TCommand command) inner,
  }) : _permissionChecker = permissionChecker,
       _permissionCode = permissionCode,
       _inner = inner;

  final IPermissionChecker _permissionChecker;
  final String _permissionCode;
  final Future<TResult> Function(TCommand command) _inner;

  @override
  Future<TResult> handle(
    TCommand command,
    Future<TResult> Function(TCommand command) next,
  ) async {
    await _permissionChecker.require(_permissionCode);
    return _inner(command);
  }

  Future<TResult> handleCommand(TCommand command) => handle(command, _inner);
}
