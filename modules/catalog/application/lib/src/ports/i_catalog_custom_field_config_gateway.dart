import '../custom_fields/configure_custom_field_attributes/configure_custom_field_attributes_command.dart';
import '../custom_fields/configure_custom_field_attributes/configure_custom_field_attributes_result.dart';
import '../custom_fields/initialize_custom_field_template/initialize_custom_field_template_command.dart';
import '../custom_fields/initialize_custom_field_template/initialize_custom_field_template_result.dart';
import '../custom_fields/reorder_custom_field_groups/reorder_custom_field_groups_command.dart';
import '../custom_fields/reorder_custom_fields/reorder_custom_fields_command.dart';
import '../custom_fields/shared/custom_field_config_view_dto.dart';
import '../custom_fields/shared/custom_field_definition_dto.dart';
import '../custom_fields/shared/custom_field_group_config_dto.dart';
import '../custom_fields/upsert_custom_field/upsert_custom_field_command.dart';
import '../custom_fields/upsert_custom_field_group/upsert_custom_field_group_command.dart';

/// Port for tenant custom field configuration (EPIC-03/US-01).
abstract interface class ICatalogCustomFieldConfigGateway {
  Future<InitializeCustomFieldTemplateResult> initializeTemplate({
    required InitializeCustomFieldTemplateCommand command,
  });

  Future<CustomFieldGroupConfigDto> upsertGroup({
    required UpsertCustomFieldGroupCommand command,
  });

  Future<void> reorderGroups({
    required ReorderCustomFieldGroupsCommand command,
  });

  Future<CustomFieldDefinitionDto> upsertField({
    required UpsertCustomFieldCommand command,
  });

  Future<ConfigureCustomFieldAttributesResult> configureAttributes({
    required ConfigureCustomFieldAttributesCommand command,
  });

  Future<void> reorderFields({required ReorderCustomFieldsCommand command});

  Future<CustomFieldConfigViewDto> listConfig({required String tenantId});
}
