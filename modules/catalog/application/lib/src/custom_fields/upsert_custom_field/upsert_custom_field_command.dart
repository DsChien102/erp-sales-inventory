import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../shared/custom_field_definition_dto.dart';
import '../shared/custom_field_select_option_dto.dart';

@RequiresPermission(CatalogPermissions.manageCustomFields)
@RequiresTenant()
final class UpsertCustomFieldCommand extends CommandBase<CustomFieldDefinitionDto>
    implements ICommand<CustomFieldDefinitionDto>, ITenantScopedCommand {
  UpsertCustomFieldCommand({
    String? id,
    required this.tenantId,
    required this.groupId,
    this.fieldId,
    required this.name,
    required this.fieldType,
    this.options = const [],
    this.isActive = true,
  }) : super(id);

  @override
  final String tenantId;

  final String groupId;
  final String? fieldId;
  final String name;
  final CustomFieldType fieldType;
  final List<CustomFieldSelectOptionDto> options;
  final bool isActive;
}
