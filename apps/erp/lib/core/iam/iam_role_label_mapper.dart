/// Maps technical role codes / identifiers to user-facing Vietnamese display labels.
///
/// Strictly aligned with 4 canonical system roles in `iam.role_definitions`:
/// - `store_owner`: 'Chủ cửa hàng'
/// - `staff`: 'Nhân viên bán hàng'
/// - `warehouse`: 'Thủ kho'
/// - `accountant`: 'Kế toán'
abstract final class IamRoleLabelMapper {
  static String toDisplayLabel(String? roleCode) {
    if (roleCode == null || roleCode.trim().isEmpty) return '';
    final normalized = roleCode.trim().toLowerCase();
    return switch (normalized) {
      'store_owner' || 'owner' => 'Chủ cửa hàng',
      'staff' => 'Nhân viên bán hàng',
      'warehouse' => 'Thủ kho',
      'accountant' => 'Kế toán',
      _ => roleCode.trim(),
    };
  }

  /// Mã vai trò chuẩn (`store_owner`, `staff`, `accountant`, `warehouse`).
  static String toRoleCode(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      'store_owner' || 'owner' || 'chủ cửa hàng' => 'store_owner',
      'staff' || 'nhân viên bán hàng' => 'staff',
      'accountant' || 'kế toán' => 'accountant',
      'warehouse' || 'thủ kho' => 'warehouse',
      _ => '',
    };
  }

  /// Mô tả trên UI theo TH-01 3.4.
  static String description(String? code) {
    return switch (toRoleCode(code)) {
      'store_owner' =>
        'Quản lý toàn bộ cửa hàng (gán mặc định cho Owner khi tạo tổ chức; gán được cho thành viên khác, BR-36)',
      'staff' => 'Bán hàng và chăm sóc khách hàng',
      'accountant' => 'Công nợ, hóa đơn và báo cáo',
      'warehouse' => 'Nhập xuất, tồn kho và kiểm kê',
      _ => '',
    };
  }
}
