import 'package:vet45_shared_domain/shared_kernel_domain.dart';

/// Thrown when a custom field definition cannot be found for the tenant.
final class CustomFieldNotFoundException extends DomainException {
  CustomFieldNotFoundException({required this.fieldId}) : super('Trường thông tin không tồn tại.');

  final String fieldId;
}
