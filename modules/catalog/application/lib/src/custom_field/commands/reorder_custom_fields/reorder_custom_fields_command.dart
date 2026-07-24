import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

@RequiresPermission(CatalogPermissions.manageCustomFields)
@RequiresTenant()
final class ReorderCustomFieldsCommand extends CommandBase<void>
    implements ICommand<void>, ITenantScopedCommand {
  ReorderCustomFieldsCommand({
    String? id,
    required this.tenantId,
    required this.groupId,
    required this.orderedFieldIds,
  }) : super(id);

  @override
  final String tenantId;

  final String groupId;
  final List<String> orderedFieldIds;
}
