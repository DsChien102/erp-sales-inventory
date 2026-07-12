import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/product/shared/change_product_business_status_result.dart';

@RequiresPermission(CatalogPermissions.manageStatus)
@RequiresTenant()
final class DeactivateProductCommand extends CommandBase<ChangeProductBusinessStatusResult>
    implements ICommand<ChangeProductBusinessStatusResult>, ITenantScopedCommand {
  DeactivateProductCommand({
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
