import 'package:erp/features/inventory/data/core/inventory_rpc.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_models.dart';
import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_repository.dart';
import 'package:erp/features/inventory/logic/supplier_rebate/projected_cost_cubit.dart';
// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubInventoryRpc implements InventoryRpc {
  @override
  Future<Map<String, dynamic>> mutate({
    required String scope,
    required String idempotencyKey,
    required String fn,
    required Map<String, dynamic> params,
  }) async =>
      const {};

  @override
  Future<Map<String, dynamic>> query(
    String fn, [
    Map<String, dynamic> params = const {},
  ]) async =>
      const {};
}

class _FakeRebateRepository extends SupplierRebateRepository {
  _FakeRebateRepository() : super(rpc: _StubInventoryRpc());

  final List<({String productId, num? extraQty, num? unitPrice})> calls = [];

  @override
  Future<ProjectedCost> projectedCost({
    required String programId,
    required String productId,
    num? extraQty,
    num? unitPrice,
  }) async {
    calls.add((productId: productId, extraQty: extraQty, unitPrice: unitPrice));
    final defaultPrice = productId == 'p1' ? 100000 : 120000;
    return ProjectedCost(
      productId: productId,
      uom: 'hộp',
      progressQty: 400,
      targetQty: 1000,
      missingQty: extraQty == null ? 600 : (600 - extraQty).clamp(0, 600),
      reachesTarget: extraQty == null ? null : (400 + extraQty >= 1000),
      rebateEstimate: extraQty != null && 400 + extraQty >= 1000 ? 5000000 : null,
      avgNow: defaultPrice,
      avgProjected: extraQty != null && unitPrice != null ? 95000 : null,
      defaultUnitPrice: defaultPrice,
      financialMasked: false,
    );
  }
}

void main() {
  group('ProjectedCostCubit', () {
    test('projected_default_price_and_debounce', () {
      fakeAsync((async) {
        final rebates = _FakeRebateRepository();
        final cubit = ProjectedCostCubit(
          rebates: rebates,
          programId: 'prog-1',
          products: const [
            ProgramProduct(
              productId: 'p1',
              name: 'SP 1',
              code: 'SP1',
              baseUom: 'hộp',
            ),
            ProgramProduct(
              productId: 'p2',
              name: 'SP 2',
              code: 'SP2',
              baseUom: 'hộp',
            ),
          ],
        );

        cubit.load();
        async.flushMicrotasks();

        expect(cubit.state.productId, 'p1');
        expect(cubit.state.priceText, '100.000');
        expect(rebates.calls.single.extraQty, isNull);

        rebates.calls.clear();
        cubit.setExtraQty('5');
        async.elapse(const Duration(milliseconds: 100));
        cubit.setExtraQty('600');
        async.elapse(const Duration(milliseconds: 350));
        expect(rebates.calls, isEmpty);

        async.elapse(const Duration(milliseconds: 100));
        async.flushMicrotasks();
        expect(rebates.calls.single.extraQty, 600);
        expect(rebates.calls.single.unitPrice, 100000);
        expect(cubit.state.result?.reachesTarget, isTrue);

        // Switch product reloads default price
        rebates.calls.clear();
        cubit.selectProduct('p2');
        async.flushMicrotasks();
        expect(cubit.state.productId, 'p2');
        expect(cubit.state.priceText, '120.000');
        expect(rebates.calls.first.productId, 'p2');

        cubit.close();
      });
    });

    test('extra_qty_thousands', () {
      fakeAsync((async) {
        final rebates = _FakeRebateRepository();
        final cubit = ProjectedCostCubit(
          rebates: rebates,
          programId: 'prog-1',
          products: const [
            ProgramProduct(
              productId: 'p1',
              name: 'SP 1',
              code: 'SP1',
              baseUom: 'hộp',
            ),
          ],
        );
        cubit.load();
        async.flushMicrotasks();
        rebates.calls.clear();

        cubit.setExtraQty('1.000');
        async.elapse(const Duration(milliseconds: 450));
        async.flushMicrotasks();

        expect(rebates.calls.single.extraQty, 1000);
        cubit.close();
      });
    });
  });
}
