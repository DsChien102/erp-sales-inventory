import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/hub/warehouse_hub_summary.dart';
import 'package:erp/features/inventory/data/hub/warehouse_hub_repository.dart';
import 'package:erp/features/inventory/logic/hub/warehouse_hub_cubit.dart';
import 'package:erp/features/inventory/logic/hub/warehouse_hub_state.dart';
import 'package:erp/features/inventory/presentation/hub/warehouse_entries.dart';

class _ThrowingHubRepo extends WarehouseHubRepository {
  const _ThrowingHubRepo(this.error);
  final Object error;

  @override
  Future<WarehouseHubSummary> getSummary() async {
    throw error;
  }
}

void main() {
  group('WarehouseHubSummary', () {
    test('pending_text_joins_non_empty_groups', () {
      const summary = WarehouseHubSummary(
        activated: true,
        pending: [
          WarehousePendingGroup(
            sourceId: 'receipts',
            label: 'nhận hàng',
            items: [
              WarehousePendingItem(
                title: 'PN-01',
                subtitle: 'NCC ABC',
                icon: VIcons.cloudUpload,
                route: '/r/1',
              ),
              WarehousePendingItem(
                title: 'PN-02',
                subtitle: 'NCC XYZ',
                icon: VIcons.cloudUpload,
                route: '/r/2',
              ),
              WarehousePendingItem(
                title: 'PN-03',
                subtitle: 'NCC 123',
                icon: VIcons.cloudUpload,
                route: '/r/3',
              ),
            ],
          ),
          WarehousePendingGroup(
            sourceId: 'initial',
            label: 'số dư đầu kỳ',
            items: [
              WarehousePendingItem(
                title: 'Tồn đầu kỳ 2026',
                subtitle: 'Chờ duyệt',
                icon: VIcons.inbox,
                route: '/r/initial',
              ),
            ],
          ),
          WarehousePendingGroup(
            sourceId: 'returns',
            label: 'hàng khách trả',
            items: [],
          ),
        ],
      );

      expect(summary.pendingTotal, 4);
      expect(summary.pendingText, '3 nhận hàng · 1 số dư đầu kỳ');
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

      final setupEntriesNonOwner = warehouseAreaEntries(WarehouseArea.setup)
          .where((e) => !e.ownerOnly)
          .toList();
      expect(
        setupEntriesNonOwner.any((e) => e.title == 'Khởi tạo tồn đầu kỳ'),
        isFalse,
      );
    });

    test('entries_copy_matches_contract', () {
      // 6 khu vực
      expect(WarehouseArea.values.length, 6);
      expect(WarehouseArea.inventory.title, 'Tồn kho');
      expect(WarehouseArea.movement.title, 'Nhập, xuất & hoàn trả');
      expect(WarehouseArea.control.title, 'Kiểm kê & xử lý');
      expect(WarehouseArea.valuation.title, 'Giá trị kho');
      expect(WarehouseArea.history.title, 'Báo cáo & lịch sử');
      expect(WarehouseArea.setup.title, 'Thiết lập kho');

      // Tạm 2 route theo Q-a1
      final receiptsEntry = warehouseAreaEntries(WarehouseArea.movement)
          .firstWhere((e) => e.id == 'receipts');
      expect(receiptsEntry.route, '/warehouse/receipts/new');

      final valEntry = warehouseAreaEntries(WarehouseArea.valuation)
          .firstWhere((e) => e.id == 'valuation_queue');
      expect(valEntry.route, '/warehouse/valuation/queue');

      // Quick action
      expect(warehouseQuickActions.length, 4);
      expect(warehouseQuickActions.first.label, 'Nhận hàng');
      expect(warehouseQuickActions.first.route, '/warehouse/receipts/new');
    });
  });

  group('WarehouseHubCubit', () {
    test('cubit_loads_summary_and_owner', () async {
      final cubit = WarehouseHubCubit(
        repository: const WarehouseHubRepository(),
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
        repository: const _ThrowingHubRepo(
          AppException(AppErrorCode.network),
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
