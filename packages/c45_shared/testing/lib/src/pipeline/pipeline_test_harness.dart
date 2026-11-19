import 'package:c45_shared_application/application.dart';
import 'package:c45_shared_infrastructure/infrastructure.dart';

/// Builds an isolated command pipeline for decorator tests.
final class PipelineTestHarness<TCommand extends ICommand<TResult>, TResult> {
  PipelineTestHarness({
    required Future<TResult> Function(TCommand command) handler,
    List<ICommandPipelineBehavior<TCommand, TResult>> behaviors = const [],
  }) : _handler = handler,
       _behaviors = behaviors;

  final Future<TResult> Function(TCommand command) _handler;
  final List<ICommandPipelineBehavior<TCommand, TResult>> _behaviors;

  Future<TResult> Function(TCommand command) build() {
    var step = _handler;
    for (final behavior in _behaviors.reversed) {
      final next = step;
      step = (command) => behavior.handle(command, next);
    }
    return step;
  }
}
