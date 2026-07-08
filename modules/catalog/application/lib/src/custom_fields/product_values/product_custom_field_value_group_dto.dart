import 'product_custom_field_value_field_dto.dart';

/// Product custom field values grouped by configured custom field group.
final class ProductCustomFieldValueGroupDto {
  const ProductCustomFieldValueGroupDto({
    required this.groupId,
    required this.name,
    this.iconKey,
    this.sortOrder = 0,
    this.fields = const [],
  });

  final String groupId;
  final String name;
  final String? iconKey;
  final int sortOrder;
  final List<ProductCustomFieldValueFieldDto> fields;
}
