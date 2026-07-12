import 'product_custom_field_value_group_dto.dart';

/// Custom field values for one product, shaped for forms and cards.
final class ProductCustomFieldValuesDto {
  const ProductCustomFieldValuesDto({
    required this.productId,
    this.groups = const [],
  });

  final String productId;
  final List<ProductCustomFieldValueGroupDto> groups;
}
