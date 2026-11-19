import '../cqrs/i_command.dart';
import '../cqrs/i_query.dart';

abstract interface class IModuleMediator {
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command);
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query);
}
