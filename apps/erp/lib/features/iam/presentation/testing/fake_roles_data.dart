import '../roles/models/role_ui_model.dart';

/// Dữ liệu mẫu vai trò hệ thống cho test widget.
abstract final class FakeRolesData {
  static const List<RoleUiModel> sampleRoles = [
    RoleUiModel(
      id: 'store_owner',
      title: 'Chủ cửa hàng',
      description: 'Quản lý toàn bộ cửa hàng',
      isCurrent: true,
      memberNames: ['Nguyễn Văn An'],
    ),
    RoleUiModel(
      id: 'staff',
      title: 'Nhân viên bán hàng',
      description: 'Bán hàng và chăm sóc khách hàng',
    ),
    RoleUiModel(
      id: 'accountant',
      title: 'Kế toán',
      description: 'Công nợ, hóa đơn và báo cáo',
    ),
    RoleUiModel(
      id: 'warehouse',
      title: 'Thủ kho',
      description: 'Nhập xuất, tồn kho và kiểm kê',
    ),
  ];
}
