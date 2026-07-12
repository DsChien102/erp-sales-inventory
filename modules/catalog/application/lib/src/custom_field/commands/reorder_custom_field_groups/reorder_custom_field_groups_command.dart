import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

@RequiresPermission(CatalogPermissions.manageCustomFields)
@RequiresTenant()
final class ReorderCustomFieldGroupsCommand extends CommandBase<void>
    implements ICommand<void>, ITenantScopedCommand {
  ReorderCustomFieldGroupsCommand({
    String? id,
    required this.tenantId,
    required this.orderedGroupIds,
  }) : super(id);

  @override
  final String tenantId;

  final List<String> orderedGroupIds;
}
