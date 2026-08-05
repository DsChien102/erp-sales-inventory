import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

/// Recording decorator over [IIamModule] for widget/Cubit tests.
final class RecordingIamModule implements IIamModule {
  RecordingIamModule(this.delegate);

  final IIamModule delegate;
  final List<Object> commands = <Object>[];
  final List<Object> queries = <Object>[];

  @override
  Future<TResult> executeCommandAsync<TResult>(
    ICommand<TResult> command,
  ) async {
    commands.add(command);
    return delegate.executeCommandAsync<TResult>(command);
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(
    IQuery<TResult> query,
  ) async {
    queries.add(query);
    return delegate.executeQueryAsync<TResult>(query);
  }

  Iterable<T> commandsOf<T>() => commands.whereType<T>();

  Iterable<T> queriesOf<T>() => queries.whereType<T>();
}
