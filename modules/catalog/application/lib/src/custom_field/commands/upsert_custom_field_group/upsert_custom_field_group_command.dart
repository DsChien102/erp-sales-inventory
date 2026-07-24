import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/custom_field/shared/custom_field_group_config_dto.dart';

@RequiresPermission(CatalogPermissions.manageCustomFields)
@RequiresTenant()
final class UpsertCustomFieldGroupCommand extends CommandBase<CustomFieldGroupConfigDto>
    implements ICommand<CustomFieldGroupConfigDto>, ITenantScopedCommand {
  UpsertCustomFieldGroupCommand({
    String? id,
    required this.tenantId,
    this.groupId,
    required this.name,
    this.iconKey,
    this.isActive = true,
  }) : super(id);

  @override
  final String tenantId;

  final String? groupId;
  final String name;
  final String? iconKey;
  final bool isActive;
}
