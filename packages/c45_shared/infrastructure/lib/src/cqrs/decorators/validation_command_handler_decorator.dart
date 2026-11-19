import 'package:c45_shared_application/application.dart';

final class ValidationCommandHandlerDecorator<TCommand extends ICommand<TResult>, TResult> {
  ValidationCommandHandlerDecorator({
    required ICommandValidator<TCommand> validator,
    required Future<TResult> Function(TCommand command) inner,
  }) : _validator = validator,
       _inner = inner;

  final ICommandValidator<TCommand> _validator;
  final Future<TResult> Function(TCommand command) _inner;

  Future<TResult> handle(TCommand command) async {
    await _validator.validate(command);
    return _inner(command);
  }
}
