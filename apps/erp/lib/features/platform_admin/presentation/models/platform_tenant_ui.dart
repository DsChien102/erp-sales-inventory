import 'package:erp/core/iam/iam_role_label_mapper.dart';
import 'package:erp/core/session/models/tenant_context.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../data/models/platform_tenant.dart';

extension TenantStatusUi on TenantStatus {
  String get label => switch (this) {
    TenantStatus.active => 'Đang hoạt động',
    TenantStatus.suspended => 'Đã tạm ngừng',
    TenantStatus.closed => 'Đã đóng',
  };

  VComponentTone get tone => switch (this) {
    TenantStatus.active => VComponentTone.success,
    TenantStatus.suspended => VComponentTone.danger,
    TenantStatus.closed => VComponentTone.danger,
  };

  /// Thao tác vòng đời mở ra ở C3 theo trạng thái (BR-12, BR-13).
  bool get canSuspend => this == TenantStatus.active;

  bool get canRestore => this == TenantStatus.suspended;

  bool get canClose => this == TenantStatus.active || this == TenantStatus.suspended;

  bool get canChangeOwner => this == TenantStatus.active || this == TenantStatus.suspended;

  bool get hasActions => canSuspend || canRestore || canClose || canChangeOwner;
}

/// Hai chữ cái đầu của tên, dùng cho ô avatar.
String initialsOf(String name, {String fallback = 'TC'}) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.length >= 2) {
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
  if (words.isNotEmpty) {
    final word = words.first;
    return word.substring(0, word.length < 2 ? word.length : 2).toUpperCase();
  }
  return fallback;
}

extension PlatformTenantMemberUi on PlatformTenantMember {
  /// Tên hiển thị; thiếu tên thì dùng email.
  String get displayName {
    final trimmed = fullName.trim();
    return trimmed.isNotEmpty ? trimmed : email;
  }

  /// Nhãn vai trò tiếng Việt (RPC trả `role_label` hoặc mã vai trò).
  String get roleDisplay {
    final label = IamRoleLabelMapper.toDisplayLabel(roleLabel);
    return label.isEmpty ? 'Thành viên tổ chức' : label;
  }
}
