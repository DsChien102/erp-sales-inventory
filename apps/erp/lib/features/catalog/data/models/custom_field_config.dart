/// Custom field configuration models and enums (EPIC-03/US-01).
library;

import 'custom_field_filter_option.dart';

/// Supported custom field types (EPIC-03/US-01/FR-04).
enum CustomFieldType {
  text,
  number,
  date,
  boolean,
  singleSelect,
}

/// Active/inactive status for custom field groups and fields (EPIC-03/US-01).
enum CustomFieldConfigStatus {
  active,
  inactive,
}

CustomFieldType fieldTypeFromRpc(String? value) {
  return CustomFieldType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => CustomFieldType.text,
  );
}

CustomFieldConfigStatus statusFromRpc(String? value) {
  return CustomFieldConfigStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => CustomFieldConfigStatus.active,
  );
}

/// Tenant custom field configuration view (EPIC-03/US-01).
final class CustomFieldConfigViewDto {
  const CustomFieldConfigViewDto({required this.groups});

  final List<CustomFieldGroupConfigDto> groups;

  factory CustomFieldConfigViewDto.fromJson(Map<String, dynamic> row) {
    final groupsRaw = row['groups'];
    if (groupsRaw is! List) {
      return const CustomFieldConfigViewDto(groups: []);
    }

    return CustomFieldConfigViewDto(
      groups: groupsRaw
          .whereType<Map<String, dynamic>>()
          .map(CustomFieldGroupConfigDto.fromJson)
          .toList(growable: false),
    );
  }
}

/// Custom field group in tenant config (EPIC-03/US-01).
final class CustomFieldGroupConfigDto {
  const CustomFieldGroupConfigDto({
    required this.groupId,
    required this.name,
    this.iconKey,
    this.sortOrder = 0,
    this.status = CustomFieldConfigStatus.active,
    this.fieldCount = 0,
    this.requiredFieldCount = 0,
    this.fields = const [],
  });

  final String groupId;
  final String name;
  final String? iconKey;
  final int sortOrder;
  final CustomFieldConfigStatus status;
  final int fieldCount;
  final int requiredFieldCount;
  final List<CustomFieldDefinitionDto> fields;

  factory CustomFieldGroupConfigDto.fromJson(Map<String, dynamic> row) {
    final fieldsRaw = row['fields'];
    final fields = fieldsRaw is List
        ? fieldsRaw
            .whereType<Map<String, dynamic>>()
            .map(CustomFieldDefinitionDto.fromJson)
            .toList(growable: false)
        : const <CustomFieldDefinitionDto>[];

    return CustomFieldGroupConfigDto(
      groupId: row['group_id'] as String,
      name: customFieldGroupDisplayName(row['name'] as String),
      iconKey: row['icon_key'] as String?,
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
      status: statusFromRpc(row['status'] as String?),
      fieldCount: (row['field_count'] as num?)?.toInt() ?? fields.length,
      requiredFieldCount: (row['required_field_count'] as num?)?.toInt() ?? 0,
      fields: fields,
    );
  }
}

/// Custom field definition in tenant config (EPIC-03/US-01).
final class CustomFieldDefinitionDto {
  const CustomFieldDefinitionDto({
    required this.fieldId,
    required this.groupId,
    required this.name,
    required this.fieldType,
    this.options = const [],
    this.isRequired = false,
    this.isSearchable = false,
    this.isFilterable = false,
    this.displayOnList = false,
    this.sortOrder = 0,
    this.status = CustomFieldConfigStatus.active,
    this.hasProductValues = false,
  });

  final String fieldId;
  final String groupId;
  final String name;
  final CustomFieldType fieldType;
  final List<CustomFieldSelectOptionDto> options;
  final bool isRequired;
  final bool isSearchable;
  final bool isFilterable;
  final bool displayOnList;
  final int sortOrder;
  final CustomFieldConfigStatus status;

  /// True when at least one [product_custom_field_values] row exists for this field.
  final bool hasProductValues;

  factory CustomFieldDefinitionDto.fromJson(Map<String, dynamic> row) {
    final optionsRaw = row['options'];
    final options = optionsRaw is List
        ? optionsRaw
            .whereType<Map<String, dynamic>>()
            .map(CustomFieldSelectOptionDto.fromJson)
            .toList(growable: false)
        : const <CustomFieldSelectOptionDto>[];

    return CustomFieldDefinitionDto(
      fieldId: row['field_id'] as String,
      groupId: row['group_id'] as String,
      name: row['name'] as String,
      fieldType: fieldTypeFromRpc(row['field_type'] as String?),
      options: options,
      isRequired: row['is_required'] as bool? ?? false,
      isSearchable: row['is_searchable'] as bool? ?? false,
      isFilterable: row['is_filterable'] as bool? ?? false,
      displayOnList: row['display_on_list'] as bool? ?? false,
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
      status: statusFromRpc(row['status'] as String?),
      hasProductValues: row['has_product_values'] as bool? ?? false,
    );
  }
}

