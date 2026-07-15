import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';

abstract final class CustomFieldRpcMapper {
  static Map<String, dynamic> initializeTemplateParams({
    required InitializeCustomFieldTemplateCommand command,
  }) {
    return <String, dynamic>{
      'p_tenant_id': command.tenantId,
      'p_template_id': command.templateId,
    };
  }

  static Map<String, dynamic> upsertGroupParams({
    required UpsertCustomFieldGroupCommand command,
  }) {
    return <String, dynamic>{
      'p_tenant_id': command.tenantId,
      'p_group_id': command.groupId,
      'p_name': command.name,
      'p_icon_key': command.iconKey,
      'p_is_active': command.isActive,
    };
  }

  static Map<String, dynamic> reorderGroupsParams({
    required ReorderCustomFieldGroupsCommand command,
  }) {
    return <String, dynamic>{
      'p_tenant_id': command.tenantId,
      'p_ordered_group_ids': command.orderedGroupIds,
    };
  }

  static Map<String, dynamic> upsertFieldParams({
    required UpsertCustomFieldCommand command,
  }) {
    return <String, dynamic>{
      'p_tenant_id': command.tenantId,
      'p_group_id': command.groupId,
      'p_field_id': command.fieldId,
      'p_name': command.name,
      'p_field_type': command.fieldType.name,
      'p_options': command.options
          .map(
            (option) => <String, dynamic>{
              'option_id': option.optionId,
              'label': option.label,
              'sort_order': option.sortOrder,
              'is_active': option.isActive,
            },
          )
          .toList(growable: false),
      'p_is_active': command.isActive,
    };
  }

  static Map<String, dynamic> configureAttributesParams({
    required ConfigureCustomFieldAttributesCommand command,
  }) {
    return <String, dynamic>{
      'p_tenant_id': command.tenantId,
      'p_field_id': command.fieldId,
      'p_is_required': command.isRequired,
      'p_is_searchable': command.isSearchable,
      'p_is_filterable': command.isFilterable,
      'p_display_on_list': command.displayOnList,
    };
  }

  static Map<String, dynamic> reorderFieldsParams({
    required ReorderCustomFieldsCommand command,
  }) {
    return <String, dynamic>{
      'p_tenant_id': command.tenantId,
      'p_group_id': command.groupId,
      'p_ordered_field_ids': command.orderedFieldIds,
    };
  }

  static Map<String, dynamic> listConfigParams({required String tenantId}) {
    return <String, dynamic>{'p_tenant_id': tenantId};
  }

  static Map<String, dynamic> getProductCustomFieldValuesParams({
    required String tenantId,
    required String productId,
    bool includeInactiveValues = false,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_product_id': productId,
      'p_include_inactive_values': includeInactiveValues,
    };
  }

  static Map<String, dynamic> upsertProductCustomFieldValuesParams({
    required UpsertCustomFieldValuesCommand command,
  }) {
    return <String, dynamic>{
      'p_tenant_id': command.tenantId,
      'p_product_id': command.productId,
      'p_values': command.values
          .map(productCustomFieldValueInputToJson)
          .toList(
            growable: false,
          ),
    };
  }

  static Map<String, dynamic> productCustomFieldValueInputToJson(
    ProductCustomFieldValueInput input,
  ) {
    final json = <String, dynamic>{'field_id': input.fieldId};
    if (input.textValue != null) {
      json['text_value'] = input.textValue;
    }
    if (input.numberValue != null) {
      json['number_value'] = input.numberValue;
    }
    if (input.dateValue != null) {
      json['date_value'] = _dateOnly(input.dateValue!);
    }
    if (input.booleanValue != null) {
      json['boolean_value'] = input.booleanValue;
    }
    if (input.optionId != null) {
      json['option_id'] = input.optionId;
    }
    return json;
  }

  static InitializeCustomFieldTemplateResult initializeTemplateResult(
    Map<String, dynamic> row,
  ) {
    return InitializeCustomFieldTemplateResult(
      groupsCreated: (row['groups_created'] as num?)?.toInt() ?? 0,
      fieldsCreated: (row['fields_created'] as num?)?.toInt() ?? 0,
      skippedCount: (row['skipped_count'] as num?)?.toInt() ?? 0,
    );
  }

  static ConfigureCustomFieldAttributesResult configureAttributesResult(
    Map<String, dynamic> row,
  ) {
    final fieldRow = row['field'];
    if (fieldRow is! Map<String, dynamic>) {
      throw StateError('Configure attributes response missing field.');
    }

    return ConfigureCustomFieldAttributesResult(
      field: fieldFromJson(fieldRow),
      existingProductsMissingCount: (row['existing_products_missing_count'] as num?)?.toInt() ?? 0,
    );
  }

  static CustomFieldConfigViewDto configViewFromJson(Map<String, dynamic> row) {
    final groupsRaw = row['groups'];
    if (groupsRaw is! List) {
      return const CustomFieldConfigViewDto(groups: []);
    }

    return CustomFieldConfigViewDto(
      groups: groupsRaw
          .whereType<Map<String, dynamic>>()
          .map(groupFromJson)
          .toList(growable: false),
    );
  }

  static ProductCustomFieldValuesDto productCustomFieldValuesFromJson(
    Map<String, dynamic> row,
  ) {
    final groupsRaw = row['groups'];
    final groups = groupsRaw is List
        ? groupsRaw
              .whereType<Map<String, dynamic>>()
              .map(productCustomFieldValueGroupFromJson)
              .toList(growable: false)
        : const <ProductCustomFieldValueGroupDto>[];

    return ProductCustomFieldValuesDto(
      productId: row['product_id'] as String,
      groups: groups,
    );
  }

  static UpsertCustomFieldValuesResult upsertProductCustomFieldValuesResultFromJson(
    Map<String, dynamic> row,
  ) {
    final valuesRow = Map<String, dynamic>.from(row['values'] as Map);
    final readinessRow = Map<String, dynamic>.from(
      row['readiness_summary'] as Map,
    );

    return UpsertCustomFieldValuesResult(
      productId: row['product_id'] as String,
      values: productCustomFieldValuesFromJson(valuesRow),
      readinessSummary: readinessSummaryFromJson(readinessRow),
    );
  }

  static ProductCustomFieldValueGroupDto productCustomFieldValueGroupFromJson(
    Map<String, dynamic> row,
  ) {
    final fieldsRaw = row['fields'];
    final fields = fieldsRaw is List
        ? fieldsRaw
              .whereType<Map<String, dynamic>>()
              .map(productCustomFieldValueFieldFromJson)
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

  static ProductCustomFieldValueFieldDto productCustomFieldValueFieldFromJson(
    Map<String, dynamic> row,
  ) {
    final optionsRaw = row['options'];
    final options = optionsRaw is List
        ? optionsRaw.whereType<Map<String, dynamic>>().map(optionFromJson).toList(growable: false)
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

  static CustomFieldGroupCardDto customFieldGroupCardFromJson(
    Map<String, dynamic> row,
  ) {
    final fieldsRaw = row['fields'];
    final fields = fieldsRaw is List
        ? fieldsRaw
              .whereType<Map<String, dynamic>>()
              .map(customFieldCardFieldFromJson)
              .toList(growable: false)
        : const <CustomFieldCardFieldDto>[];

    return CustomFieldGroupCardDto(
      groupId: row['group_id'] as String,
      name: customFieldGroupDisplayName(row['name'] as String),
      iconKey: row['icon_key'] as String?,
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
      fields: fields,
      hasRequiredMissing: row['has_required_missing'] as bool? ?? false,
    );
  }

  static CustomFieldCardFieldDto customFieldCardFieldFromJson(
    Map<String, dynamic> row,
  ) {
    return CustomFieldCardFieldDto(
      fieldId: row['field_id'] as String,
      name: row['name'] as String,
      fieldType: row['field_type'] as String,
      displayValue: row['display_value'] as String?,
      isRequired: row['is_required'] as bool? ?? false,
      isMissing: row['is_missing'] as bool? ?? false,
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
      isActive: row['is_active'] as bool? ?? true,
    );
  }

  static ReadinessSummaryDto readinessSummaryFromJson(
    Map<String, dynamic> row,
  ) {
    final blockersRaw = row['blockers'];
    final blockers = blockersRaw is List
        ? blockersRaw
              .whereType<Map<String, dynamic>>()
              .map(
                (blocker) => ReadinessBlockerDto(
                  code: blocker['code'] as String,
                  message: blocker['message'] as String,
                  group: blocker['group'] as String?,
                ),
              )
              .toList(growable: false)
        : const <ReadinessBlockerDto>[];

    return ReadinessSummaryDto(
      status: readinessStatusFromRpc(row['status'] as String?),
      blockers: blockers,
    );
  }

  static List<CustomFieldValueValidationErrorDto> validationErrorsFromJson(
    Object? value,
  ) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(
          (error) => CustomFieldValueValidationErrorDto(
            fieldId: error['field_id'] as String,
            groupId: error['group_id'] as String?,
            code: error['code'] as String? ?? 'invalid',
            message: error['message'] as String,
          ),
        )
        .toList(growable: false);
  }

  static CustomFieldGroupConfigDto groupFromJson(Map<String, dynamic> row) {
    final fieldsRaw = row['fields'];
    final fields = fieldsRaw is List
        ? fieldsRaw.whereType<Map<String, dynamic>>().map(fieldFromJson).toList(growable: false)
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

  static CustomFieldDefinitionDto fieldFromJson(Map<String, dynamic> row) {
    final optionsRaw = row['options'];
    final options = optionsRaw is List
        ? optionsRaw.whereType<Map<String, dynamic>>().map(optionFromJson).toList(growable: false)
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

  static CustomFieldSelectOptionDto optionFromJson(Map<String, dynamic> row) {
    return CustomFieldSelectOptionDto(
      optionId: row['option_id'] as String,
      label: row['label'] as String,
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
      isActive: row['is_active'] as bool? ?? true,
    );
  }

  static ReadinessStatus readinessStatusFromRpc(String? value) {
    return switch (value) {
      'readyToSell' || 'ready_to_sell' => ReadinessStatus.readyToSell,
      _ => ReadinessStatus.incomplete,
    };
  }

  static CustomFieldType fieldTypeFromRpc(String? value) {
    return CustomFieldType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => CustomFieldType.text,
    );
  }

  static CustomFieldConfigStatus statusFromRpc(String? value) {
    return CustomFieldConfigStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => CustomFieldConfigStatus.active,
    );
  }

  static String _dateOnly(DateTime dateTime) {
    final utc = dateTime.toUtc();
    final year = utc.year.toString().padLeft(4, '0');
    final month = utc.month.toString().padLeft(2, '0');
    final day = utc.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static DateTime? _toDate(Object? value) {
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

  static double? _toDouble(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  static Map<String, dynamic> listCustomFieldFilterOptionsParams({
    required String tenantId,
    required int maxOptionsPerField,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_max_options_per_field': maxOptionsPerField,
    };
  }

  static List<CustomFieldFilterOptionDto> filterOptionsFromJson(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(filterOptionFromJson)
        .toList(growable: false);
  }

  static CustomFieldFilterOptionDto filterOptionFromJson(
    Map<String, dynamic> row,
  ) {
    final optionsRaw = row['options'];
    final options = optionsRaw is List
        ? optionsRaw
              .whereType<Map<String, dynamic>>()
              .map(selectOptionFromJson)
              .toList(growable: false)
        : const <CustomFieldSelectOptionDto>[];

    return CustomFieldFilterOptionDto(
      fieldId: row['field_id'] as String,
      groupId: row['group_id'] as String,
      groupName: customFieldGroupDisplayName(row['group_name'] as String),
      fieldName: row['field_name'] as String,
      fieldType: row['field_type'] as String,
      options: options,
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  static CustomFieldSelectOptionDto selectOptionFromJson(
    Map<String, dynamic> row,
  ) {
    return CustomFieldSelectOptionDto(
      optionId: row['option_id'] as String,
      label: row['label'] as String,
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
      isActive: row['is_active'] as bool? ?? true,
    );
  }

  static Map<String, dynamic> getProductCustomFieldSnapshotParams({
    required String tenantId,
    required List<String> productIds,
    required bool includeInactiveValues,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_product_ids': productIds,
      'p_include_inactive_values': includeInactiveValues,
    };
  }

  static ProductCustomFieldSnapshotDto snapshotFromJson(
    Map<String, dynamic> row,
  ) {
    final productsRaw = row['products'];
    if (productsRaw is! Map) {
      return const ProductCustomFieldSnapshotDto(products: {});
    }

    final products = <String, List<ProductCustomFieldSnapshotFieldDto>>{};
    for (final entry in productsRaw.entries) {
      final fieldsRaw = entry.value;
      if (fieldsRaw is! List) {
        continue;
      }
      products[entry.key.toString()] = fieldsRaw
          .whereType<Map<String, dynamic>>()
          .map(snapshotFieldFromJson)
          .toList(growable: false);
    }

    return ProductCustomFieldSnapshotDto(products: products);
  }

  static ProductCustomFieldSnapshotFieldDto snapshotFieldFromJson(
    Map<String, dynamic> row,
  ) {
    return ProductCustomFieldSnapshotFieldDto(
      productId: row['product_id'] as String,
      fieldId: row['field_id'] as String,
      groupId: row['group_id'] as String,
      groupName: customFieldGroupDisplayName(row['group_name'] as String),
      fieldName: row['field_name'] as String,
      fieldType: row['field_type'] as String,
      displayValue: row['display_value'] as String?,
      textValue: row['text_value'] as String?,
      numberValue: _toDouble(row['number_value']),
      dateValue: _toDate(row['date_value']),
      booleanValue: row['boolean_value'] as bool?,
      optionId: row['option_id'] as String?,
      optionLabel: row['option_label'] as String?,
      isActive: row['is_active'] as bool? ?? true,
    );
  }

  static List<CustomFieldListValueDto> listValuesFromJson(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value.whereType<Map<String, dynamic>>().map(listValueFromJson).toList(growable: false);
  }

  static CustomFieldListValueDto listValueFromJson(Map<String, dynamic> row) {
    return CustomFieldListValueDto(
      fieldId: row['field_id'] as String,
      groupId: row['group_id'] as String,
      groupName: customFieldGroupDisplayName(row['group_name'] as String),
      fieldName: row['field_name'] as String,
      fieldType: row['field_type'] as String,
      displayValue: row['display_value'] as String,
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
