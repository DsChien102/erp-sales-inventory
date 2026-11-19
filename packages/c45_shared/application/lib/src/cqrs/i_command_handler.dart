import 'i_command.dart';

abstract interface class ICommandHandler<TCommand extends ICommand<TResult>, TResult> {
  Future<TResult> handle(TCommand command);
}
