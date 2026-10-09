import 'tenant_context.dart';

/// Một tổ chức người dùng được vào, dùng cho sheet chọn tổ chức.
final class AccessibleTenant {
  const AccessibleTenant({
    required this.id,
    required this.name,
    required this.code,
    required this.roleCode,
    required this.status,
    this.isOwner = false,
    this.isCurrent = false,
  });

  final String id;
  final String name;
  final String code;

  /// Giá trị thô `role`. Nhãn hiển thị map ở widget.
  final String roleCode;
  final TenantStatus status;
  final bool isOwner;
  final bool isCurrent;

  /// Active, hoặc tổ chức đang provisioning mà người dùng là chủ.
  bool get isSelectable =>
      status == TenantStatus.active || (status == TenantStatus.provisioning && isOwner);

  factory AccessibleTenant.fromJson(
    Map<String, dynamic> row, {
    required bool isCurrent,
  }) {
    final id = row['tenant_id'] as String;
    return AccessibleTenant(
      id: id,
      name: row['name'] as String,
      code: codeFor(id),
      roleCode: row['role'] as String,
      status: tenantStatusFromWire(row['status'] as String?),
      isOwner: row['is_owner'] as bool? ?? false,
      isCurrent: isCurrent,
    );
  }

  AccessibleTenant copyWith({bool? isCurrent}) {
    return AccessibleTenant(
      id: id,
      name: name,
      code: code,
      roleCode: roleCode,
      status: status,
      isOwner: isOwner,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }

  /// `TEN-` + 6 ký tự đầu (bỏ ký tự không phải chữ/số), như mapper UI cũ.
  static String codeFor(String tenantId) {
    final compact = tenantId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (compact.isEmpty) return 'TEN-UNKNOWN';
    final suffix = compact.length <= 6
        ? compact.toUpperCase()
        : compact.substring(0, 6).toUpperCase();
    return 'TEN-$suffix';
  }
}
