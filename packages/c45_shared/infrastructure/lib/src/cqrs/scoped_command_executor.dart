import 'package:get_it/get_it.dart';
import 'package:c45_shared_application/application.dart';

import 'command_bus.dart';
import 'query_bus.dart';

typedef LifetimeScopeFn<T> =
    Future<T> Function(Future<T> Function(GetIt scope) action, {String? scopeName});

/// Shared per-request command/query entry point with GetIt lifetime scopes.
abstract final class ScopedCommandExecutor {
  static Future<TResult> executeCommand<TResult>({
    required ICommand<TResult> command,
    required Future<TResult> Function(
      Future<TResult> Function(GetIt scope) action, {
      String? scopeName,
    }) lifetimeScope,
    required String scopeNamePrefix,
  }) {
    return lifetimeScope(
      (container) => container.get<CommandBus>().execute(command),
      scopeName: '$scopeNamePrefix-${command.id}',
    );
  }

  static Future<TResult> executeQuery<TResult>({
    required IQuery<TResult> query,
    required Future<TResult> Function(
      Future<TResult> Function(GetIt scope) action, {
      String? scopeName,
    }) lifetimeScope,
  }) {
    return lifetimeScope(
      (container) => container.get<QueryBus>().execute(query),
    );
  }
}
