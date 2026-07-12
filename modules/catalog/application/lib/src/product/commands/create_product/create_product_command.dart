import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'create_product_result.dart';
import 'package:vet45_catalog_application/src/product/shared/product_image_input.dart';

@RequiresPermission(CatalogPermissions.create)
@RequiresTenant()
final class CreateProductCommand extends CommandBase<CreateProductResult>
    implements ICommand<CreateProductResult>, ITenantScopedCommand {
  CreateProductCommand({
    String? id,
    required this.tenantId,
    required this.actorId,
    required this.productName,
    this.referenceId,
    this.commercialName,
    this.sku,
    this.barcode,
    this.description,
    this.note,
    this.images = const [],
    this.baseUnitName,
  }) : super(id);

  @override
  final String tenantId;

  final String actorId;
  final String productName;
  final String? referenceId;
  final String? commercialName;
  final String? sku;
  final String? barcode;
  final String? description;
  final String? note;
  final List<ProductImageInput> images;
  final String? baseUnitName;
}
