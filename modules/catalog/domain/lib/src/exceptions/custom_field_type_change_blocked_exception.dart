import 'package:vet45_shared_domain/shared_kernel_domain.dart';

/// Thrown when changing a custom field type after product values already exist.
final class CustomFieldTypeChangeBlockedException extends DomainException {
  CustomFieldTypeChangeBlockedException({required this.fieldId})
    : super(
        'Không đổi được kiểu dữ liệu vì trường thông tin đã có dữ liệu trên sản phẩm.',
      );

  final String fieldId;
}
