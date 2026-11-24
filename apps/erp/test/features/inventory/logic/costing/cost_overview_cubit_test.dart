import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/costing/costing_models.dart';
import 'package:erp/features/inventory/data/costing/costing_repository.dart';
import 'package:erp/features/inventory/data/stock/stock_models.dart';
import 'package:erp/features/inventory/logic/costing/cost_overview_cubit.dart';
import 'package:erp/features/inventory/logic/costing/cost_overview_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCostingRepository implements CostingRepository {
  CostOverview? overviewResult;
  Object? overviewError;
  Object? setPolicyError;
  int overviewCalls = 0;

  @override
  Future<CostOverview> overview() async {
    overviewCalls++;
    if (overviewError != null) throw overviewError!;
    return overviewResult!;
  }

  @override
  Future<({CostMethod method, bool methodLocked})> setPolicy({
    required String idempotencyKey,
    required CostMethod method,
  }) async {
    if (setPolicyError != null) throw setPolicyError!;
    return (method: method, methodLocked: false);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeCostingRepository repo;

  setUp(() {
    repo = _FakeCostingRepository();
  });

  test('overview_denied', () async {
    repo.overviewError = const AppException(
      InventoryErrorCode.permissionDenied,
    );
    final cubit = CostOverviewCubit(repo);
    final states = <CostOverviewState>[];
    final sub = cubit.stream.listen(states.add);

    await cubit.load();
    await pumpEventQueue();
    await sub.cancel();
    await cubit.close();

    expect(states, [
      const CostOverviewState(status: CostOverviewStatus.loading),
      const CostOverviewState(status: CostOverviewStatus.denied),
    ]);
  });

  test('change_method_locked_shows_message_and_reloads', () async {
    repo.overviewResult = const CostOverview(
      method: CostMethod.moving,
      methodLocked: true,
      hasPendingRun: false,
      runs: [],
    );
    repo.setPolicyError = const AppException(
      InventoryErrorCode.costPolicyLocked,
    );
    final cubit = CostOverviewCubit(repo);
    cubit.emit(
      const CostOverviewState(
        status: CostOverviewStatus.ready,
        data: CostOverview(
          method: CostMethod.moving,
          methodLocked: false,
          hasPendingRun: false,
          runs: [],
        ),
      ),
    );
    final states = <CostOverviewState>[];
    final sub = cubit.stream.listen(states.add);

    final ok = await cubit.changeMethod(CostMethod.periodic);
    await pumpEventQueue();
    await sub.cancel();
    await cubit.close();

    expect(ok, isFalse);
    expect(repo.overviewCalls, 1);
    expect(states[0].savingMethod, isTrue);
    expect(states[1].savingMethod, isFalse);
    expect(
      states[1].message,
      'Đã công bố giá vốn nên không đổi được phương pháp.',
    );
    expect(states[2].status, CostOverviewStatus.ready);
    expect(states[2].data?.methodLocked, isTrue);
  });
}
