import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_rpc.dart';
import 'package:erp/features/inventory/data/hub/warehouse_hub_summary.dart';
import 'package:erp/features/inventory/data/hub/warehouse_hub_repository.dart';
import 'package:erp/features/inventory/logic/hub/warehouse_hub_cubit.dart';
import 'package:erp/features/inventory/logic/hub/warehouse_hub_state.dart';
import 'package:erp/features/inventory/presentation/hub/warehouse_entries.dart';
import 'package:vet45_design_system/design_system.dart';

class _MockInventoryRpc extends Mock implements InventoryRpc {}

class _ThrowingHubRepo extends WarehouseHubRepository {
  _ThrowingHubRepo(this.error) : super(rpc: _MockInventoryRpc());
  final Object error;

  @override
  Future<WarehouseHubSummary> getSummary() async {
    throw error;
  }
}

class _SuccessHubRepo extends WarehouseHubRepository {
  _SuccessHubRepo(this._summary) : super(rpc: _MockInventoryRpc());
  final WarehouseHubSummary _summary;

  @override
  Future<WarehouseHubSummary> getSummary() async {
    return _summary;
  }
}

void main() {
  group('WarehouseHubSummary', () {
    test('activated_and_problems_fields', () {
      const summary = WarehouseHubSummary(
        activated: true,
        problems: WarehouseAttention(count: 2, text: '2 hàng hỏng'),
      );

      expect(summary.activated, isTrue);
      expect(summary.problems?.count, 2);
      expect(summary.problems?.text, '2 hàng hỏng');
    });
  });

  group('WarehouseEntries', () {
    test('area_entries_filter_owner_only', () {
      final valuationEntriesNonOwner = warehouseAreaEntries(WarehouseArea.valuation)
          .where((e) => !e.ownerOnly)
          .toList();
      expect(
        valuationEntriesNonOwner.any((e) => e.title == 'Giá vốn'),
        isFalse,
      );
    });

    test('entries_copy_matches_contract', () {
      // 6 khu vực (đã thêm lại setup theo G5-2a)
      expect(WarehouseArea.values.length, 6);
      expect(WarehouseArea.inventory.title, 'Tồn kho');
      expect(WarehouseArea.movement.title, 'Nhập, xuất & hoàn trả');
      expect(WarehouseArea.control.title, 'Kiểm kê & xử lý');
      expect(WarehouseArea.valuation.title, 'Giá trị kho');
      expect(WarehouseArea.history.title, 'Báo cáo & lịch sử');
      expect(WarehouseArea.setup.title, 'Thiết lập kho');
      expect(WarehouseArea.setup.subtitle, 'Các việc thiết lập ít dùng');
      expect(WarehouseArea.setup.icon, VIcons.inbox);

      final stockPolicyEntry = warehouseAreaEntries(WarehouseArea.setup)
          .firstWhere((e) => e.id == 'stock_policy');
      expect(stockPolicyEntry.route, '/warehouse/stock-policy');
      expect(stockPolicyEntry.subtitle, 'Thiết lập ngưỡng tồn và chính sách cảnh báo');
      expect(stockPolicyEntry.icon, VIcons.shield);

      // Tạm 2 route theo Q-a1
      final receiptsEntry = warehouseAreaEntries(WarehouseArea.movement)
          .firstWhere((e) => e.id == 'receipts');
      expect(receiptsEntry.route, '/warehouse/receipts/new');

      final valEntry = warehouseAreaEntries(WarehouseArea.valuation)
          .firstWhere((e) => e.id == 'valuation_queue');
      expect(valEntry.route, '/warehouse/valuation/queue');

      // Quick action (3 nút: Nhận hàng, Kiểm kê, Tra cứu tồn — đã bỏ Lấy hàng)
      expect(warehouseQuickActions.length, 3);
      expect(warehouseQuickActions.first.label, 'Nhận hàng');
      expect(warehouseQuickActions.first.route, '/warehouse/receipts/new');
      expect(warehouseQuickActions.any((a) => a.label == 'Lấy hàng'), isFalse);
    });
  });

  group('WarehouseHubCubit', () {
    test('cubit_loads_summary_and_owner', () async {
      final cubit = WarehouseHubCubit(
        repository: _SuccessHubRepo(const WarehouseHubSummary(activated: true)),
        isOwner: () => true,
      );

      expect(cubit.state, isA<WarehouseHubLoading>());
      await cubit.load();

      expect(cubit.state, isA<WarehouseHubLoaded>());
      final loaded = cubit.state as WarehouseHubLoaded;
      expect(loaded.isOwner, isTrue);
      expect(loaded.summary.activated, isTrue);
    });

    test('cubit_error_message_from_app_exception', () async {
      final cubit = WarehouseHubCubit(
        repository: _ThrowingHubRepo(
          const AppException(AppErrorCode.network),
        ),
        isOwner: () => false,
      );

      await cubit.load();
      expect(cubit.state, isA<WarehouseHubError>());
      final err = cubit.state as WarehouseHubError;
      expect(err.message, const AppException(AppErrorCode.network).userMessage());
    });
  });
}
