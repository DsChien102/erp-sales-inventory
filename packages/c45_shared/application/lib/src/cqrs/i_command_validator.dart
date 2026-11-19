abstract interface class ICommandValidator<TCommand> {
  Future<void> validate(TCommand command);
}
