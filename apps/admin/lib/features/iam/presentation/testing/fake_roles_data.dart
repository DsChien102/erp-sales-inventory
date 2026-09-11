import '../roles/models/role_ui_model.dart';

/// Dữ liệu mẫu vai trò hệ thống phục vụ hiển thị & testing (TA-D-01 & TA-D-02).
abstract final class FakeRolesData {
  static const List<RoleUiModel> sampleRoles = [
    RoleUiModel(
      id: 'role-owner',
      title: 'Chủ cửa hàng',
      description: 'Quản lý toàn bộ cửa hàng',
      permissionCount: 38,
      isCurrent: true,
      groups: [
        PermissionGroupUiModel(
          title: 'Quản lý chung & Thiết lập',
          items: [
            PermissionItemUiModel(
              title: 'Toàn quyền cấu hình',
              description: 'Thay đổi thông tin cửa hàng, phân quyền và thiết lập thanh toán',
            ),
            PermissionItemUiModel(
              title: 'Xem báo cáo doanh thu & tài chính',
              description: 'Truy cập đầy đủ báo cáo tổng quan và chi tiết kinh doanh',
            ),
          ],
        ),
      ],
    ),
    RoleUiModel(
      id: 'role-sales',
      title: 'Nhân viên bán hàng',
      description: 'Bán hàng và chăm sóc khách hàng',
      permissionCount: 14,
      isCurrent: false,
      groups: [
        PermissionGroupUiModel(
          title: 'Bán hàng',
          items: [
            PermissionItemUiModel(
              title: 'Tạo và sửa đơn hàng',
              description: 'Tạo giao dịch trong cửa hàng',
            ),
            PermissionItemUiModel(
              title: 'Thu tiền',
              description: 'Ghi nhận thanh toán được phép',
            ),
            PermissionItemUiModel(
              title: 'Đổi trả hàng',
              description: 'Tiếp nhận đổi trả theo chính sách',
            ),
          ],
        ),
        PermissionGroupUiModel(
          title: 'Khách hàng & sản phẩm',
          items: [
            PermissionItemUiModel(
              title: 'Xem và cập nhật khách hàng',
              description: 'Quản lý thông tin liên hệ',
            ),
            PermissionItemUiModel(
              title: 'Xem giá và tồn kho',
              description: 'Tra cứu thông tin phục vụ bán hàng',
            ),
          ],
        ),
      ],
    ),
    RoleUiModel(
      id: 'role-accountant',
      title: 'Kế toán',
      description: 'Công nợ, hóa đơn và báo cáo',
      permissionCount: 18,
      isCurrent: false,
      groups: [
        PermissionGroupUiModel(
          title: 'Tài chính & Kế toán',
          items: [
            PermissionItemUiModel(
              title: 'Quản lý hóa đơn & chứng từ',
              description: 'Xuất hóa đơn và đối soát chứng từ thanh toán',
            ),
            PermissionItemUiModel(
              title: 'Theo dõi công nợ',
              description: 'Quản lý công nợ khách hàng và nhà cung cấp',
            ),
          ],
        ),
      ],
    ),
    RoleUiModel(
      id: 'role-warehouse',
      title: 'Thủ kho',
      description: 'Nhập xuất, tồn kho và kiểm kê',
      permissionCount: 12,
      isCurrent: false,
      groups: [
        PermissionGroupUiModel(
          title: 'Quản lý kho',
          items: [
            PermissionItemUiModel(
              title: 'Nhập xuất kho',
              description: 'Tạo phiếu nhập và xuất hàng',
            ),
            PermissionItemUiModel(
              title: 'Kiểm kê kho',
              description: 'Thực hiện kiểm kê và điều chỉnh số lượng tồn',
            ),
          ],
        ),
      ],
    ),
  ];
}
