import 'package:erp/features/inventory/data/costing/costing_models.dart';
import 'package:erp/features/inventory/data/costing/costing_repository.dart';
import 'package:erp/features/inventory/data/stock/stock_models.dart';
import 'package:erp/features/inventory/logic/costing/cost_versions_cubit.dart';
import 'package:erp/features/inventory/logic/costing/cost_versions_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCostingRepository implements CostingRepository {
  CostVersionList? result;
  Object? error;

  @override
  Future<CostVersionList> versions(String productId) async {
    if (error != null) throw error!;
    return result!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeCostingRepository repo;

  setUp(() {
    repo = _FakeCostingRepository();
  });

  test('loads cost versions successfully', () async {
    repo.result = CostVersionList(
      productId: 'p1',
      name: 'SP 1',
      uom: 'hộp',
      versions: [
        CostVersion(
          versionId: 'v1',
          unitCost: 11000,
          method: CostMethod.periodic,
          runCode: 'GV-2611-01',
          publishedAt: DateTime(2026, 11, 3),
        ),
      ],
    );
    final cubit = CostVersionsCubit(repo);
    final states = <CostVersionsState>[];
    final sub = cubit.stream.listen(states.add);

    await cubit.load('p1');
    await pumpEventQueue();
    await sub.cancel();
    await cubit.close();

    expect(states[0].status, CostVersionsStatus.loading);
    expect(states[1].status, CostVersionsStatus.ready);
    expect(states[1].data?.versions.length, 1);
  });
}
