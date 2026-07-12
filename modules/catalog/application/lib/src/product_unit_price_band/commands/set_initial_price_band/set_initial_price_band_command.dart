import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

@RequiresPermission(CatalogPermissions.managePricing)
@RequiresTenant()
final class SetInitialPriceBandCommand extends CommandBase<void>
    implements ICommand<void>, ITenantScopedCommand {
  SetInitialPriceBandCommand({
    String? id,
    required this.tenantId,
    required this.productId,
    this.productUnitId,
    this.listPrice,
    this.floorPrice,
    this.useStoreRule = false,
  }) : super(id);

  @override
  final String tenantId;
  final String productId;
  final String? productUnitId;
  final double? listPrice;
  final double? floorPrice;
  final bool? useStoreRule;
}
