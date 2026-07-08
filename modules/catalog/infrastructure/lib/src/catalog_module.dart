import 'package:get_it/get_it.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

final class CatalogModule implements ICatalogModule {
  CatalogModule(this._container);

  final GetIt _container;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    return _container.get<CommandBus>().execute(command);
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    return _container.get<QueryBus>().execute(query);
  }
}
