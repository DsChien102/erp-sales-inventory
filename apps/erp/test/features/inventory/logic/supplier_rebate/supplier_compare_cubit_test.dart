import 'package:erp/features/inventory/data/core/inventory_rpc.dart';
import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_models.dart';
import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_repository.dart';
import 'package:erp/features/inventory/logic/supplier_rebate/supplier_compare_cubit.dart';
import 'package:erp/features/inventory/logic/supplier_rebate/supplier_compare_state.dart';
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

  @override
  Future<SupplierCompare> compareSuppliers(String productId) async {
    return const SupplierCompare(
      productId: 'p1',
      name: 'Nobivac DHPPi',
      code: 'NB-01',
      uom: 'hộp',
      financialMasked: false,
      suppliers: [
        SupplierCompareRow(
          partnerId: 'A',
          name: 'NCC A',
          isSystem: false,
          avgLandedUnitCost: 97200,
          receiptCount: 2,
          paidQty: 1000,
          freeQty: 0,
        ),
        SupplierCompareRow(
          partnerId: 'B',
          name: 'NCC B',
          isSystem: false,
          avgLandedUnitCost: 99000,
          receiptCount: 1,
          paidQty: 500,
          freeQty: 0,
        ),
        SupplierCompareRow(
          partnerId: 'SYS',
          name: 'Mua lẻ / khác',
          isSystem: true,
          avgLandedUnitCost: 90000,
          receiptCount: 1,
          paidQty: 10,
          freeQty: 0,
        ),
      ],
    );
  }
}

void main() {
  group('SupplierCompareCubit', () {
    test('compare_cheapest', () async {
      final cubit = SupplierCompareCubit(
        rebates: _FakeRebateRepository(),
        productId: 'p1',
      );
      expect(cubit.state, isA<SupplierCompareLoading>());

      await cubit.load();
      expect(cubit.state, isA<SupplierCompareLoaded>());
      final loaded = cubit.state as SupplierCompareLoaded;
      expect(loaded.cheapestId, 'A');
      expect(loaded.data.suppliers.length, 3);
      await cubit.close();
    });
  });
}

