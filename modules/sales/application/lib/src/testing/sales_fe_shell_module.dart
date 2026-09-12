import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'sales_fake_contract_fixture_factory.dart';
import 'sales_fake_data.dart';

/// FE shell mediator: always returns success fixtures for supported contracts.
///
/// Used until Sales BE/codegen is wired. Prefer [FakeSalesModule] in tests when
/// scenario-specific outcomes are required.
final class SalesFeShellModule implements ISalesModule {
  const SalesFeShellModule();

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    return _execute<TResult>(command.runtimeType.toString(), 'command');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    if (query is GetSalesOrderDetailQuery) {
      return Future<TResult>.value(
        SalesFakeData.findOrderDetail((query as GetSalesOrderDetailQuery).salesOrderId) as TResult,
      );
    }
    return _execute<TResult>(query.runtimeType.toString(), 'query');
  }

  Future<TResult> _execute<TResult>(String requestType, String requestKind) {
    if (!SalesFakeContractFixtureFactory.supports(requestType)) {
      throw UnsupportedError(
        'SalesFeShellModule: unsupported $requestKind $requestType',
      );
    }
    return Future<TResult>.value(
      SalesFakeContractFixtureFactory.create(requestType) as TResult,
    );
  }
}
