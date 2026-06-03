/// Command pipeline middleware contract.
abstract interface class ICommandPipelineBehavior<TCommand, TResult> {
  Future<TResult> handle(
    TCommand command,
    Future<TResult> Function(TCommand command) next,
  );
}
