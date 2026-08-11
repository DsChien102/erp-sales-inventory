/// Data model cho mục quyền hạn chi tiết trong nhóm quyền.
final class PermissionItemUiModel {
  final String title;
  final String description;

  const PermissionItemUiModel({
    required this.title,
    required this.description,
  });
}

/// Data model cho nhóm quyền (ví dụ: Bán hàng, Khách hàng & sản phẩm).
final class PermissionGroupUiModel {
  final String title;
  final List<PermissionItemUiModel> items;

  const PermissionGroupUiModel({
    required this.title,
    required this.items,
  });
}

/// Data model cho Vai trò hệ thống.
final class RoleUiModel {
  final String id;
  final String title;
  final String description;
  final int permissionCount;
  final bool isCurrent;
  final List<PermissionGroupUiModel> groups;

  const RoleUiModel({
    required this.id,
    required this.title,
    required this.description,
    required this.permissionCount,
    this.isCurrent = false,
    this.groups = const [],
  });
}
