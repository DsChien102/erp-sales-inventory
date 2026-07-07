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
      existingProductsMissingCount:
          (row['existing_products_missing_count'] as num?)?.toInt() ?? 0,
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

  static CustomFieldGroupConfigDto groupFromJson(Map<String, dynamic> row) {
    final fieldsRaw = row['fields'];
    final fields = fieldsRaw is List
        ? fieldsRaw
              .whereType<Map<String, dynamic>>()
              .map(fieldFromJson)
              .toList(growable: false)
        : const <CustomFieldDefinitionDto>[];

    return CustomFieldGroupConfigDto(
      groupId: row['group_id'] as String,
      name: row['name'] as String,
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
        ? optionsRaw
              .whereType<Map<String, dynamic>>()
              .map(optionFromJson)
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
}
