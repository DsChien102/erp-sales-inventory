import 'package:vet45_shared_application/application.dart';

import '../contracts/i_sales_module.dart';
import 'sales_fake_contract_fixture_factory.dart';
import 'sales_fake_scenario_definition.dart';
import 'sales_fake_scenario_registry.dart';

/// Contract fake selected by a canonical TH-05 scenario ID.
///
/// Typed success/error fixtures are added to this mediator together with the
/// corresponding slice contract. Unknown requests always fail explicitly.
final class FakeSalesModule implements ISalesModule {
  FakeSalesModule({required this.scenarioId}) {
    if (!SalesFakeScenarioRegistry.contains(scenarioId)) {
      throw ArgumentError.value(
        scenarioId,
        'scenarioId',
        'Unknown TH-05 fake scenario ID',
      );
    }
  }

  final String scenarioId;

  SalesFakeScenarioDefinition get scenario => SalesFakeScenarioRegistry.definitionFor(scenarioId);

  Object get scenarioFixture => SalesFakeContractFixtureFactory.createScenarioFixture(scenario);

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    return _execute<TResult>(command.runtimeType.toString(), 'command');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    return _execute<TResult>(query.runtimeType.toString(), 'query');
  }

  Future<TResult> _execute<TResult>(String requestType, String requestKind) {
    if (!SalesFakeContractFixtureFactory.supports(requestType)) {
      throw UnsupportedError(
        'FakeSalesModule: unsupported $requestKind $requestType',
      );
    }
    final requestResult = SalesFakeContractFixtureFactory.resultContractFor(requestType);
    if (requestResult != scenario.resultFamily) {
      throw UnsupportedError(
        'FakeSalesModule: scenario $scenarioId provides '
        '${scenario.resultFamily}, not $requestResult for $requestType',
      );
    }
    final error = SalesFakeContractFixtureFactory.errorFor(scenario);
    if (error != null) throw error;
    return Future<TResult>.value(
      SalesFakeContractFixtureFactory.create(requestType) as TResult,
    );
  }
}
