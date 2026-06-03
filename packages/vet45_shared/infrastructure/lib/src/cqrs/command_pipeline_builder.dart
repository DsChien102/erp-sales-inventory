typedef CommandStep<TCommand, TResult> =
    Future<TResult> Function(TCommand command);

/// Composes command handler middleware in outer-to-inner order.
final class CommandPipelineBuilder<TCommand, TResult> {
  CommandPipelineBuilder(CommandStep<TCommand, TResult> inner) : _step = inner;

  CommandStep<TCommand, TResult> _step;

  CommandPipelineBuilder<TCommand, TResult> wrap(
    Future<TResult> Function(
      TCommand command,
      CommandStep<TCommand, TResult> next,
    ) middleware,
  ) {
    final next = _step;
    _step = (command) => middleware(command, next);
    return this;
  }

  CommandStep<TCommand, TResult> build() => _step;
}
