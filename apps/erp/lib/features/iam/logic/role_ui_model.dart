/// Một vai trò hệ thống trên danh mục và trang chi tiết.
final class RoleUiModel {
  const RoleUiModel({
    required this.id,
    required this.title,
    required this.description,
    this.isCurrent = false,
    this.memberNames = const [],
  });

  /// Mã vai trò (`store_owner`, `staff`, `accountant`, `warehouse`).
  final String id;
  final String title;
  final String description;

  /// Có thành viên đang giữ vai trò.
  final bool isCurrent;
  final List<String> memberNames;
}
