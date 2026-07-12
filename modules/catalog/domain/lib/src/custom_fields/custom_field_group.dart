import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'custom_field_config_status.dart';
import 'rules/custom_field_group_name_required_rule.dart';

/// Tenant-configurable custom field group (Nhóm thông tin).
final class CustomFieldGroup extends Entity<String> implements IAggregateRoot {
  CustomFieldGroup._({
    required super.id,
    required this.tenantId,
    required this.name,
    required this.status,
    required this.sortOrder,
    this.icon,
  });

  final String tenantId;
  final String name;
  final CustomFieldConfigStatus status;
  final int sortOrder;
  final String? icon;

  factory CustomFieldGroup.create({
    required String id,
    required String tenantId,
    required String name,
    int sortOrder = 0,
    String? icon,
  }) {
    final trimmed = name.trim();
    final group = CustomFieldGroup._(
      id: id,
      tenantId: tenantId,
      name: trimmed,
      status: CustomFieldConfigStatus.active,
      sortOrder: sortOrder,
      icon: icon?.trim().isEmpty == true ? null : icon?.trim(),
    );
    group.checkRule(CustomFieldGroupNameRequiredRule(trimmed));
    return group;
  }

  factory CustomFieldGroup.reconstitute({
    required String id,
    required String tenantId,
    required String name,
    required CustomFieldConfigStatus status,
    required int sortOrder,
    String? icon,
  }) {
    return CustomFieldGroup._(
      id: id,
      tenantId: tenantId,
      name: name,
      status: status,
      sortOrder: sortOrder,
      icon: icon,
    );
  }

  CustomFieldGroup rename(String name) {
    final trimmed = name.trim();
    checkRule(CustomFieldGroupNameRequiredRule(trimmed));
    return CustomFieldGroup._(
      id: id,
      tenantId: tenantId,
      name: trimmed,
      status: status,
      sortOrder: sortOrder,
      icon: icon,
    );
  }

  CustomFieldGroup changeIcon(String? icon) {
    final normalized = icon?.trim();
    return CustomFieldGroup._(
      id: id,
      tenantId: tenantId,
      name: name,
      status: status,
      sortOrder: sortOrder,
      icon: (normalized == null || normalized.isEmpty) ? null : normalized,
    );
  }

  CustomFieldGroup reorder(int sortOrder) {
    return CustomFieldGroup._(
      id: id,
      tenantId: tenantId,
      name: name,
      status: status,
      sortOrder: sortOrder,
      icon: icon,
    );
  }

  CustomFieldGroup deactivate() {
    return CustomFieldGroup._(
      id: id,
      tenantId: tenantId,
      name: name,
      status: CustomFieldConfigStatus.inactive,
      sortOrder: sortOrder,
      icon: icon,
    );
  }

  CustomFieldGroup reactivate() {
    return CustomFieldGroup._(
      id: id,
      tenantId: tenantId,
      name: name,
      status: CustomFieldConfigStatus.active,
      sortOrder: sortOrder,
      icon: icon,
    );
  }
}
