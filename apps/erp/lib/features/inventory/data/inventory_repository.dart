import 'package:vet45_design_system/design_system.dart';

import 'models/warehouse_manual_action.dart';
import 'models/warehouse_task_item.dart';

class InventoryRepository {
  const InventoryRepository();

  Future<List<WarehouseTaskItem>> getPendingTasks() async {
    return const [
      WarehouseTaskItem(
        id: 'PN-260816-04',
        title: 'PN-260816-04',
        subtitle: 'Minh Dũng · 2 dòng hàng',
        icon: VIcons.cloudUpload,
        badgeLabel: 'Cần nhận',
        badgeTone: VComponentTone.success,
        routePath: '/warehouse/receipts/approval/REC-240715-01',
      ),
      WarehouseTaskItem(
        id: 'SO-260827-21',
        title: 'SO-260827-21',
        subtitle: 'Đại lý An Phú · 2 sản phẩm',
        icon: VIcons.inventory,
        badgeLabel: 'Đang lấy',
        badgeTone: VComponentTone.info,
      ),
      WarehouseTaskItem(
        id: 'KK-0709-03',
        title: 'KK-0709-03',
        subtitle: 'Kho trung tâm · 12/38 đã đếm',
        icon: VIcons.checkList,
        badgeLabel: 'Đang đếm',
        badgeTone: VComponentTone.info,
      ),
    ];
  }

  List<WarehouseTaskItem> getLookupUtilities() {
    return const [
      WarehouseTaskItem(
        id: 'lookup_stock',
        title: 'Tồn kho',
        subtitle: 'Tra cứu số lượng, lô và khả dụng',
        icon: VIcons.warehouse,
      ),
      WarehouseTaskItem(
        id: 'lookup_reports',
        title: 'Báo cáo & thẻ kho',
        subtitle: 'Xem tồn tại thời điểm và lịch sử biến động',
        icon: VIcons.history,
      ),
      WarehouseTaskItem(
        id: 'valuation_queue',
        title: 'Hàng chờ xác lập giá trị',
        subtitle: 'Xác lập giá trị nhập ban đầu cho hàng đã nhận',
        icon: VIcons.receipt,
        routePath: '/warehouse/valuation/queue',
      ),
      WarehouseTaskItem(
        id: 'lookup_all_features',
        title: 'Tất cả chức năng kho',
        subtitle: 'Xem các chức năng và thiết lập khác',
        icon: VIcons.listView,
      ),
    ];
  }

  List<WarehouseManualAction> getManualActions() {
    return const [
      WarehouseManualAction(
        id: 'quick_receipt',
        title: 'Nhập hàng nhanh',
        subtitle: 'Hàng đã đến nhưng chưa có chứng từ mua',
        icon: VIcons.cloudUpload,
        routePath: '/warehouse/receipts/quick/header',
      ),
      WarehouseManualAction(
        id: 'new_count',
        title: 'Tạo phiên kiểm kê',
        subtitle: 'Bắt đầu một lần kiểm kê mới',
        icon: VIcons.checkList,
      ),
      WarehouseManualAction(
        id: 'change_state',
        title: 'Chuyển tình trạng hàng',
        subtitle: 'Tạm ngừng bán, hỏng hoặc dùng thử',
        icon: VIcons.shield,
      ),
      WarehouseManualAction(
        id: 'create_disposal',
        title: 'Tạo yêu cầu tiêu hủy',
        subtitle: 'Lập yêu cầu tiêu hủy hàng có kiểm soát',
        icon: VIcons.ban,
      ),
    ];
  }
}
