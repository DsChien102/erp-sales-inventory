import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'price_band_source_type.dart';
import 'set_product_unit_price_band_result.dart';

/// Stub command for slice #11 — manual price band entry / override.
@RequiresPermission(CatalogPermissions.managePricing)
@RequiresTenant()
final class SetProductUnitPriceBandCommand
    extends CommandBase<SetProductUnitPriceBandResult>
    implements ICommand<SetProductUnitPriceBandResult>, ITenantScopedCommand {
  SetProductUnitPriceBandCommand({
    String? id,
    required this.tenantId,
    required this.productId,
    required this.listPrice,
    required this.floorPrice,
    this.productUnitId,
    this.sourceType = PriceBandSourceType.manual,
    this.storePriceRuleId,
  }) : super(id);

  @override
  final String tenantId;
  final String productId;
  final String? productUnitId;
  final double listPrice;
  final double floorPrice;
  final PriceBandSourceType sourceType;
  final String? storePriceRuleId;
}
