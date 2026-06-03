import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

/// Captures executed queries for assertions in tests.
final class RecordingQueryBus {
  RecordingQueryBus() : _bus = QueryBus();

  final QueryBus _bus;
  IQuery<dynamic>? lastQuery;

  void register<TQuery extends IQuery<TResult>, TResult>(
    IQueryHandler<TQuery, TResult> handler,
  ) {
    _bus.register<TQuery, TResult>(handler.handle);
  }

  Future<TResult> execute<TResult>(IQuery<TResult> query) {
    lastQuery = query;
    return _bus.execute(query);
  }
}
