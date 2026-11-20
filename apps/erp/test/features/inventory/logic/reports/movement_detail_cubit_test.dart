import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/reports/reports_models.dart';
import 'package:erp/features/inventory/data/reports/reports_repository.dart';
import 'package:erp/features/inventory/logic/reports/movement_detail_cubit.dart';
import 'package:erp/features/inventory/logic/reports/report_status.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repo implements ReportsRepository {
  Object? error;

  @override
  Future<MovementDetail> movementDetail(String movementId) async {
    if (error != null) throw error!;
    return MovementDetail(
      movementId: movementId,
      product: const StockCardProduct(
        productId: 'p1',
        name: 'X',
        code: 'X1',
        uom: 'hộp',
        isLotTracked: false,
      ),
      movementKind: 'RECEIPT',
      intentType: 'GOODS_RECEIPT',
      quantityDelta: 20,
      beforeQty: 28,
      afterQty: 48,
      businessDate: DateTime(2026, 9, 4),
      recordedAt: DateTime(2026, 9, 4, 8),
      actorName: 'Chủ',
      source: const MovementSource(kind: 'RECEIPT', docCode: 'PN-1'),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('movement_detail_load_ready', () async {
    final cubit = MovementDetailCubit(_Repo(), 'm1');
    await cubit.load();
    expect(cubit.state.status, ReportStatus.ready);
    expect(cubit.state.data!.movementId, 'm1');
    await cubit.close();
  });

  test('movement_detail_denied', () async {
    final repo = _Repo()
      ..error = const AppException(InventoryErrorCode.permissionDenied);
    final cubit = MovementDetailCubit(repo, 'm1');
    await cubit.load();
    expect(cubit.state.status, ReportStatus.denied);
    await cubit.close();
  });
}
