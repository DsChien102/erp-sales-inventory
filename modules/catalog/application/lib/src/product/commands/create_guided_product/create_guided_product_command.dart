import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/product_custom_field_value/commands/upsert_custom_field_values/product_custom_field_value_input.dart';
import 'package:vet45_catalog_application/src/product_unit_price_band/queries/list_product_unit_price_bands/price_band_source_type.dart';
import 'package:vet45_catalog_application/src/shared/base_unit_selection.dart';
import 'create_guided_product_result.dart';
import 'package:vet45_catalog_application/src/product/shared/product_image_input.dart';

@RequiresPermission(CatalogPermissions.create)
@RequiresTenant()
final class CreateGuidedProductCommand extends CommandBase<CreateGuidedProductResult>
    implements ICommand<CreateGuidedProductResult>, ITenantScopedCommand {
  CreateGuidedProductCommand({
    String? id,
    required this.tenantId,
    required this.actorId,
    required this.productName,
    this.commercialName,
    this.sku,
    this.barcode,
    this.note,
    this.images = const [],
    this.baseUnit,
    this.basicStockQuantityBase,
    this.basePrice,
    this.listBeforeVat,
    this.floorBeforeVat,
    this.useStorePriceRule = false,
    this.priceBandSourceType,
    this.listMarkupRatio,
    this.floorMarkupRatio,
    this.customFieldValues = const [],
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
  final String productName;
  final String? commercialName;
  final String? sku;
  final String? barcode;
  final String? note;
  final List<ProductImageInput> images;
  final BaseUnitSelection? baseUnit;
  final int? basicStockQuantityBase;
  final double? basePrice;
  final int? listBeforeVat;
  final int? floorBeforeVat;
  final bool useStorePriceRule;
  final PriceBandSourceType? priceBandSourceType;
  final double? listMarkupRatio;
  final double? floorMarkupRatio;
  final List<ProductCustomFieldValueInput> customFieldValues;
}
