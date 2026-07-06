import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'update_product_profile_result.dart';

@RequiresPermission(CatalogPermissions.update)
@RequiresTenant()
final class UpdateProductProfileCommand extends CommandBase<UpdateProductProfileResult>
    implements ICommand<UpdateProductProfileResult>, ITenantScopedCommand {
  UpdateProductProfileCommand({
    String? id,
    required this.tenantId,
    required this.actorId,
    required this.productId,
    required this.productName,
    this.commercialName,
    this.sku,
    this.barcode,
    this.description,
    this.note,
    this.expectedVersion,
  }) : super(id);

  @override
  final String tenantId;

  final String actorId;
  final String productId;
  final String productName;
  final String? commercialName;
  final String? sku;
  final String? barcode;
  final String? description;
  final String? note;
  final int? expectedVersion;
}
