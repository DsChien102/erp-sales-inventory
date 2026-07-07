import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'change_product_business_status_result.dart';

@RequiresPermission(CatalogPermissions.manageStatus)
@RequiresTenant()
final class ReactivateProductCommand extends CommandBase<ChangeProductBusinessStatusResult>
    implements ICommand<ChangeProductBusinessStatusResult>, ITenantScopedCommand {
  ReactivateProductCommand({
    String? id,
    required this.tenantId,
    required this.actorId,
    required this.productId,
    this.reason,
    this.expectedVersion,
  }) : super(id);

  @override
  final String tenantId;

  final String actorId;
  final String productId;
  final String? reason;
  final int? expectedVersion;
}
