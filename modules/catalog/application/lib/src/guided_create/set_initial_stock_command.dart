import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

@RequiresPermission(CatalogPermissions.manageStock)
@RequiresTenant()
final class SetInitialStockCommand extends CommandBase<void>
    implements ICommand<void>, ITenantScopedCommand {
  SetInitialStockCommand({
    String? id,
    required this.tenantId,
    required this.productId,
    required this.quantity,
  }) : super(id);

  @override
  final String tenantId;
  final String productId;
  final int quantity;
}
