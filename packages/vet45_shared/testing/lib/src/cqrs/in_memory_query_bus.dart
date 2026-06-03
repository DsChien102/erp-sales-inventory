import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

/// In-memory [QueryBus] for handler tests.
final class InMemoryQueryBus {
  InMemoryQueryBus() : _bus = QueryBus();

  final QueryBus _bus;

  void registerHandler<TQuery extends IQuery<TResult>, TResult>(
    IQueryHandler<TQuery, TResult> handler,
  ) {
    _bus.register<TQuery, TResult>(handler.handle);
  }

  Future<TResult> execute<TResult>(IQuery<TResult> query) {
    return _bus.execute(query);
  }
}
