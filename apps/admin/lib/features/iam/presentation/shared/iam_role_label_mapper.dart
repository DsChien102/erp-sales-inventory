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
}
