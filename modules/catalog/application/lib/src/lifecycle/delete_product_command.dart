import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'change_product_soft_delete_result.dart';

@RequiresPermission(CatalogPermissions.delete)
@RequiresTenant()
final class DeleteProductCommand extends CommandBase<ChangeProductSoftDeleteResult>
    implements ICommand<ChangeProductSoftDeleteResult>, ITenantScopedCommand {
  DeleteProductCommand({
    String? id,
    required this.tenantId,
    required this.actorId,
    required this.productId,
    this.reason,
    this.expectedVersion,
    this.confirmAcknowledgeWarnings = false,
  }) : super(id);

  @override
  final String tenantId;

  final String actorId;
  final String productId;
  final String? reason;
  final int? expectedVersion;
  final bool confirmAcknowledgeWarnings;
}
