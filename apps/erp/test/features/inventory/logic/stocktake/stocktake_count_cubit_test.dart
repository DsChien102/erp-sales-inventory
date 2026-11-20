import 'package:erp/features/inventory/data/stocktake/stocktake_models.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_repository.dart';
import 'package:erp/features/inventory/logic/stocktake/stocktake_count_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCountRepository extends Fake implements StocktakeRepository {
  StocktakeSession session = StocktakeSession(
    id: 's1',
    code: 'KK-261112-01',
    scopeKind: StocktakeScopeKind.all,
    scopeLabel: 'Toàn kho',
    counterName: 'Nguyễn Văn An',
    reason: 'Kiểm kê định kỳ',
    status: StocktakeStatus.counting,
    openedAt: DateTime(2026, 11, 12, 18, 30),
    lines: const [
      StocktakeLine(
        lineId: 'l1',
        productId: 'p1',
        productName: 'Oxytetracycline LA',
        productCode: 'SP-000147',
        isExpired: false,
        uom: 'chai',
        isUnexpected: false,
        needsRecount: false,
        draftQty: 4.5,
      ),
      StocktakeLine(
        lineId: 'l2',
        productId: 'p2',
        productName: 'Tylosin 20%',
        productCode: 'SP-000122',
        lotId: 'lot1',
        lotCode: 'TY2511',
        isExpired: false,
        uom: 'lọ',
        isUnexpected: false,
        needsRecount: false,
      ),
    ],
  );

  final List<({String sessionId, String lineId, num? quantity})> draftCalls = [];

  @override
  Future<StocktakeSession> get(String sessionId) async => session;

  @override
  Future<void> saveDraft({
    required String sessionId,
    required String lineId,
    num? quantity,
  }) async {
    draftCalls.add((sessionId: sessionId, lineId: lineId, quantity: quantity));
  }
}

void main() {
  test(
    'count_draft_debounced calls saveDraft once with last value after 400ms',
    () async {
      final repo = _FakeCountRepository();
      final cubit = StocktakeCountCubit(repository: repo, sessionId: 's1');
      await cubit.load();

      expect(cubit.state.inputs['l1'], '4,5');
      expect(cubit.state.countedCount, 1);

      cubit.setCount('l2', '3');
      await Future<void>.delayed(const Duration(milliseconds: 150));
      cubit.setCount('l2', '3,5');
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(repo.draftCalls, isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 450));

      expect(repo.draftCalls, hasLength(1));
      expect(repo.draftCalls.single.sessionId, 's1');
      expect(repo.draftCalls.single.lineId, 'l2');
      expect(repo.draftCalls.single.quantity, 3.5);

      await cubit.close();
    },
  );
}

