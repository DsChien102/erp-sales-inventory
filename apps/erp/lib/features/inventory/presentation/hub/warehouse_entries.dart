import 'package:vet45_design_system/design_system.dart';

enum WarehouseArea {
  inventory,
  movement,
  control,
  valuation,
  history,
  setup;

  String get id => name;

  String get title => switch (this) {
        WarehouseArea.inventory => 'Tồn kho',
        WarehouseArea.movement => 'Nhập, xuất & hoàn trả',
        WarehouseArea.control => 'Kiểm kê & xử lý',
        WarehouseArea.valuation => 'Giá trị kho',
        WarehouseArea.history => 'Báo cáo & lịch sử',
        WarehouseArea.setup => 'Thiết lập kho',
      };

  String get subtitle => switch (this) {
        WarehouseArea.inventory => 'Số lượng, khả dụng, lô và tình trạng hàng',
        WarehouseArea.movement => 'Hàng đi vào, đi ra và quay lại kho',
        WarehouseArea.control =>
          'Kiểm tra thực tế, sai lệch và trường hợp bất thường',
        WarehouseArea.valuation => 'Giá nhập, chi phí mua và giá vốn',
        WarehouseArea.history => 'Thẻ kho, biến động và số liệu tra cứu',
        WarehouseArea.setup => 'Các việc thiết lập ít dùng',
      };

  VIcons get icon => switch (this) {
        WarehouseArea.inventory => VIcons.warehouse,
        WarehouseArea.movement => VIcons.inventory,
        WarehouseArea.control => VIcons.checkList,
        WarehouseArea.valuation => VIcons.coins,
        WarehouseArea.history => VIcons.history,
        WarehouseArea.setup => VIcons.inbox,
      };

  bool get ownerOnly => this == WarehouseArea.valuation;

  static WarehouseArea? fromId(String id) {
    for (final area in WarehouseArea.values) {
      if (area.id == id) return area;
    }
    return null;
  }
}

class WarehouseEntry {
  const WarehouseEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.route,
    this.ownerOnly = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final VIcons icon;
  final String? route;
  final bool ownerOnly;
}

List<WarehouseEntry> warehouseAreaEntries(WarehouseArea area) => switch (area) {
      WarehouseArea.inventory => const [
          WarehouseEntry(
            id: 'stock_availability',
            title: 'Tồn kho & khả dụng',
            subtitle: 'Tra cứu sản phẩm, số lượng, lô và khả dụng',
            icon: VIcons.warehouse,
            route: null,
          ),
        ],
      WarehouseArea.movement => const [
          WarehouseEntry(
            id: 'receipts',
            title: 'Nhận hàng',
            subtitle: 'Nhận theo chứng từ hoặc nhập nhanh',
            icon: VIcons.cloudUpload,
            route: '/warehouse/receipts/new', // tạm — G5-4
          ),
        ],
      WarehouseArea.control => const [
          WarehouseEntry(
            id: 'stocktaking',
            title: 'Kiểm kê kho',
            subtitle: 'Đếm, rà soát và xử lý chênh lệch',
            icon: VIcons.checkList,
            route: null,
          ),
        ],
      WarehouseArea.valuation => const [
          WarehouseEntry(
            id: 'valuation_queue',
            title: 'Hàng chờ xác lập giá trị',
            subtitle: 'Ghi giá nhập cho hàng đã nhận',
            icon: VIcons.success,
            route: '/warehouse/valuation/queue', // tạm — G5-5
          ),
          WarehouseEntry(
            id: 'cogs',
            title: 'Giá vốn',
            subtitle: 'Tính, rà soát và công bố giá vốn',
            icon: VIcons.coins,
            route: null,
            ownerOnly: true,
          ),
        ],
      WarehouseArea.history => const [
          WarehouseEntry(
            id: 'stock_card_reports',
            title: 'Báo cáo tồn & thẻ kho',
            subtitle: 'Xem tồn tại thời điểm và lịch sử biến động',
            icon: VIcons.history,
            route: null,
          ),
        ],
      WarehouseArea.setup => const [
          WarehouseEntry(
            id: 'stock_policy',
            title: 'Chính sách tồn & cận hạn',
            subtitle: 'Thiết lập ngưỡng tồn và chính sách cảnh báo',
            icon: VIcons.shield,
            route: '/warehouse/stock-policy',
            ownerOnly: false,
          ),
        ],
    };

class WarehouseQuickAction {
  const WarehouseQuickAction({
    required this.label,
    required this.icon,
    this.route,
    this.requiresActivation = false,
  });

  final String label;
  final VIcons icon;
  final String? route;
  final bool requiresActivation;
}

const List<WarehouseQuickAction> warehouseQuickActions = [
  WarehouseQuickAction(
    label: 'Nhận hàng',
    icon: VIcons.cloudUpload,
    route: '/warehouse/receipts/new', // tạm — G5-4
    requiresActivation: false,
  ),
  WarehouseQuickAction(
    label: 'Kiểm kê',
    icon: VIcons.checkList,
    route: '/warehouse/area/control',
    requiresActivation: false,
  ),
  WarehouseQuickAction(
    label: 'Tra cứu tồn',
    icon: VIcons.search,
    route: '/warehouse/area/inventory',
    requiresActivation: false,
  ),
];

const String warehouseStockSearchRoute = '/warehouse/area/inventory';
