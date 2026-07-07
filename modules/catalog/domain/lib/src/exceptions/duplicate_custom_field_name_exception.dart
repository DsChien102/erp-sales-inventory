import 'package:vet45_shared_domain/shared_kernel_domain.dart';

/// Thrown when a custom field name already exists within the same group.
final class DuplicateCustomFieldNameException extends DomainException {
  DuplicateCustomFieldNameException({
    required this.name,
    required this.groupId,
    this.existingFieldId,
  }) : super('Trường thông tin "$name" đã tồn tại trong nhóm.');

  final String name;
  final String groupId;
  final String? existingFieldId;
}
