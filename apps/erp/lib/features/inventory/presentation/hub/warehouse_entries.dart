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
            route: '/warehouse/stock',
          ),
        ],
      WarehouseArea.movement => const [
          WarehouseEntry(
            id: 'receipts',
            title: 'Nhận hàng',
            subtitle: 'Nhận theo chứng từ hoặc nhập nhanh',
            icon: VIcons.cloudUpload,
            route: warehouseReceiptsRoute,
          ),
        ],
      WarehouseArea.control => const [
          WarehouseEntry(
            id: 'stocktaking',
            title: 'Kiểm kê kho',
            subtitle: 'Đếm, rà soát và xử lý chênh lệch',
            icon: VIcons.checkList,
            route: '/warehouse/stocktakes',
          ),
        ],
      WarehouseArea.valuation => const [
          WarehouseEntry(
            id: 'supplier_programs',
            title: 'Chương trình nhà cung cấp',
            subtitle: 'Ưu đãi giảm giá, hàng tặng, chiết khấu đạt mốc',
            icon: VIcons.coins,
            route: '/warehouse/supplier-programs',
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
    route: warehouseReceiptNewRoute,
    requiresActivation: false,
  ),
  WarehouseQuickAction(
    label: 'Kiểm kê',
    icon: VIcons.checkList,
    route: '/warehouse/stocktakes',
    requiresActivation: false,
  ),
  WarehouseQuickAction(
    label: 'Tra cứu tồn',
    icon: VIcons.search,
    route: '/warehouse/stock',
    requiresActivation: false,
  ),
];

const String warehouseStockSearchRoute = '/warehouse/stock';
const String warehouseReceiptsRoute = '/warehouse/receipts';
const String warehouseReceiptNewRoute = '/warehouse/receipts/new';
