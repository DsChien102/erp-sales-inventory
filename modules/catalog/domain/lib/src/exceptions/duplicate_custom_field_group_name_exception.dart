import 'package:vet45_shared_domain/shared_kernel_domain.dart';

/// Thrown when a custom field group name already exists for the tenant.
final class DuplicateCustomFieldGroupNameException extends DomainException {
  DuplicateCustomFieldGroupNameException({
    required this.name,
    this.existingGroupId,
  }) : super('Nhóm thông tin "$name" đã tồn tại trong tenant.');

  final String name;
  final String? existingGroupId;
}
