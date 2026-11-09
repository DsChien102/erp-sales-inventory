import 'package:vet45_design_system/design_system.dart';
import 'warehouse_hub_summary.dart';

class WarehouseHubRepository {
  const WarehouseHubRepository();

  Future<WarehouseHubSummary> getSummary() async {
    // G5-0a trả giá trị cố định / prototype candidate; G5-0b thay thân bằng RPC inventory.get_warehouse_hub_summary
    return const WarehouseHubSummary(
      activated: true,
      pending: [
        WarehousePendingGroup(
          sourceId: 'receipts',
          label: 'nhận hàng',
          items: [
            WarehousePendingItem(
              title: 'REC-260916-04',
              subtitle: 'Minh Dũng · Kho trung tâm',
              icon: VIcons.cloudUpload,
              route: '/warehouse/receipts/new',
            ),
            WarehousePendingItem(
              title: 'REC-260916-02',
              subtitle: 'An Việt · Kho trung tâm',
              icon: VIcons.cloudUpload,
              route: '/warehouse/receipts/new',
            ),
            WarehousePendingItem(
              title: 'REC-260916-03',
              subtitle: 'Minh Phát · Kho trung tâm',
              icon: VIcons.cloudUpload,
              route: '/warehouse/receipts/new',
            ),
          ],
        ),
        WarehousePendingGroup(
          sourceId: 'returns',
          label: 'ngoại lệ lô hàng trả',
          items: [
            WarehousePendingItem(
              title: 'RET-01',
              subtitle: 'Hàng khách trả',
              icon: VIcons.refresh,
              route: '/warehouse/area/movement',
            ),
          ],
        ),
        WarehousePendingGroup(
          sourceId: 'stocktaking',
          label: 'kiểm kê',
          items: [
            WarehousePendingItem(
              title: 'AUD-01',
              subtitle: 'Kiểm kê kho',
              icon: VIcons.checkList,
              route: '/warehouse/area/control',
            ),
          ],
        ),
        WarehousePendingGroup(
          sourceId: 'status',
          label: 'đổi tình trạng',
          items: [
            WarehousePendingItem(
              title: 'STA-01',
              subtitle: 'Đổi tình trạng hàng',
              icon: VIcons.shield,
              route: '/warehouse/area/control',
            ),
          ],
        ),
        WarehousePendingGroup(
          sourceId: 'adjustment',
          label: 'sửa sai',
          items: [
            WarehousePendingItem(
              title: 'ADJ-01',
              subtitle: 'Hủy & sửa sai nghiệp vụ',
              icon: VIcons.edit,
              route: '/warehouse/area/control',
            ),
          ],
        ),
      ],
      problems: WarehouseAttention(
        count: 3,
        text: '1 lô hết hạn · 2 cách ly / hỏng',
      ),
      reconciliation: WarehouseAttention(
        count: 8,
        text: '5 sai lệch · 3 chưa rõ kết quả',
      ),
    );
  }
}
