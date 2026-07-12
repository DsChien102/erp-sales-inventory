import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'configure_custom_field_attributes_result.dart';

@RequiresPermission(CatalogPermissions.manageCustomFields)
@RequiresTenant()
final class ConfigureCustomFieldAttributesCommand
    extends CommandBase<ConfigureCustomFieldAttributesResult>
    implements ICommand<ConfigureCustomFieldAttributesResult>, ITenantScopedCommand {
  ConfigureCustomFieldAttributesCommand({
    String? id,
    required this.tenantId,
    required this.fieldId,
    required this.isRequired,
    required this.isSearchable,
    required this.isFilterable,
    required this.displayOnList,
  }) : super(id);

  @override
  final String tenantId;

  final String fieldId;
  final bool isRequired;
  final bool isSearchable;
  final bool isFilterable;
  final bool displayOnList;
}
