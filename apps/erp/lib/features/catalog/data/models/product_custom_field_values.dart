/// Product custom field values models (EPIC-03/US-02).
library;

import 'custom_field_filter_option.dart';

DateTime? _toDate(Object? value) {
  if (value == null) {
    return null;
  }
  final raw = value.toString();
  final dateOnly = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw);
  if (dateOnly != null) {
    return DateTime.utc(
      int.parse(dateOnly.group(1)!),
      int.parse(dateOnly.group(2)!),
      int.parse(dateOnly.group(3)!),
    );
  }
  return DateTime.parse(raw).toUtc();
}

double? _toDouble(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

/// Custom field values for one product, shaped for forms and cards.
final class ProductCustomFieldValuesDto {
  const ProductCustomFieldValuesDto({
    required this.productId,
    this.groups = const [],
  });

  final String productId;
  final List<ProductCustomFieldValueGroupDto> groups;

  factory ProductCustomFieldValuesDto.fromJson(Map<String, dynamic> row) {
    final groupsRaw = row['groups'];
    final groups = groupsRaw is List
        ? groupsRaw
            .whereType<Map<String, dynamic>>()
            .map(ProductCustomFieldValueGroupDto.fromJson)
            .toList(growable: false)
        : const <ProductCustomFieldValueGroupDto>[];

    return ProductCustomFieldValuesDto(
      productId: row['product_id'] as String,
      groups: groups,
    );
  }
}

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

  factory ProductCustomFieldValueGroupDto.fromJson(Map<String, dynamic> row) {
    final fieldsRaw = row['fields'];
    final fields = fieldsRaw is List
        ? fieldsRaw
            .whereType<Map<String, dynamic>>()
            .map(ProductCustomFieldValueFieldDto.fromJson)
            .toList(growable: false)
        : const <ProductCustomFieldValueFieldDto>[];

    return ProductCustomFieldValueGroupDto(
      groupId: row['group_id'] as String,
      name: customFieldGroupDisplayName(row['name'] as String),
      iconKey: row['icon_key'] as String?,
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
      fields: fields,
    );
  }
}

/// Product value row for a configured custom field.
final class ProductCustomFieldValueFieldDto {
  const ProductCustomFieldValueFieldDto({
    required this.fieldId,
    required this.groupId,
    required this.name,
    required this.fieldType,
    this.options = const [],
    this.isRequired = false,
    this.isMissing = false,
    this.sortOrder = 0,
    this.displayValue,
    this.textValue,
    this.numberValue,
    this.dateValue,
    this.booleanValue,
    this.optionId,
    this.isActive = true,
  });

  final String fieldId;
  final String groupId;
  final String name;
  final String fieldType;
  final List<CustomFieldSelectOptionDto> options;
  final bool isRequired;
  final bool isMissing;
  final int sortOrder;
  final String? displayValue;
  final String? textValue;
  final double? numberValue;
  final DateTime? dateValue;
  final bool? booleanValue;
  final String? optionId;
  final bool isActive;

  factory ProductCustomFieldValueFieldDto.fromJson(Map<String, dynamic> row) {
    final optionsRaw = row['options'];
    final options = optionsRaw is List
        ? optionsRaw
            .whereType<Map<String, dynamic>>()
            .map(CustomFieldSelectOptionDto.fromJson)
            .toList(growable: false)
        : const <CustomFieldSelectOptionDto>[];

    return ProductCustomFieldValueFieldDto(
      fieldId: row['field_id'] as String,
      groupId: row['group_id'] as String,
      name: row['name'] as String,
      fieldType: row['field_type'] as String,
      options: options,
      isRequired: row['is_required'] as bool? ?? false,
      isMissing: row['is_missing'] as bool? ?? false,
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
      displayValue: row['display_value'] as String?,
      textValue: row['text_value'] as String?,
      numberValue: _toDouble(row['number_value']),
      dateValue: _toDate(row['date_value']),
      booleanValue: row['boolean_value'] as bool?,
      optionId: row['option_id'] as String?,
      isActive: row['is_active'] as bool? ?? true,
    );
  }
}

