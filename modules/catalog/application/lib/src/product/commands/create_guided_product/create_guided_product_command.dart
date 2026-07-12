import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/product_custom_field_value/commands/upsert_custom_field_values/product_custom_field_value_input.dart';
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
    this.images = const [],
    this.baseUnit,
    this.basicStockQuantityBase,
    this.basePrice,
    this.listPrice,
    this.floorPrice,
    this.useStorePriceRule = false,
    this.customFieldValues = const [],
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
  final String productName;
  final String? commercialName;
  final String? sku;
  final String? barcode;
  final List<ProductImageInput> images;
  final BaseUnitSelection? baseUnit;
  final int? basicStockQuantityBase;
  final double? basePrice;
  final double? listPrice;
  final double? floorPrice;
  final bool useStorePriceRule;
  final List<ProductCustomFieldValueInput> customFieldValues;
}
