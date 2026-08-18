import 'package:get_it/get_it.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

/// Facade implementing [IEInvoiceModule] via the module [CommandBus]/[QueryBus].
final class EinvoiceModule implements IEInvoiceModule {
  EinvoiceModule(this._container);

  final GetIt _container;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) =>
      _container.get<CommandBus>().execute(command);

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) =>
      _container.get<QueryBus>().execute(query);
}
