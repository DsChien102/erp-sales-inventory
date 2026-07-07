import 'package:vet45_shared_domain/shared_kernel_domain.dart';

/// Thrown when a custom field group cannot be found for the tenant.
final class CustomFieldGroupNotFoundException extends DomainException {
  CustomFieldGroupNotFoundException({required this.groupId})
    : super('Nhóm thông tin không tồn tại.');

  final String groupId;
}
