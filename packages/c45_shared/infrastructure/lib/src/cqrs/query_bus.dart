import 'package:c45_shared_application/application.dart';

import '../logging/i_logger.dart';
import 'bus_execution_logger.dart';
import 'typed_bus.dart';

typedef QueryHandlerFn = Future<dynamic> Function(IQuery<dynamic> query);

final class QueryBus {
  QueryBus({ILogger? logger}) : _logger = logger, _bus = TypedBus<Object, dynamic>();

  final ILogger? _logger;
  final TypedBus<Object, dynamic> _bus;

  void register<TQuery extends IQuery<TResult>, TResult>(
    Future<TResult> Function(TQuery query) handler,
  ) {
    _bus.register<TQuery, TResult>(handler);
  }

  Future<TResult> execute<TResult>(IQuery<TResult> query) async {
    final type = query.runtimeType.toString();
    final queryId = _readQueryId(query);

    return BusExecutionLogger.run(
      logger: _logger,
      kind: 'Query',
      type: type,
      id: queryId,
      action: () async => await _bus.execute(query) as TResult,
    );
  }
}

String? _readQueryId(IQuery<dynamic> query) {
  if (query case QueryBase(:final id)) {
    return id;
  }
  return null;
}
