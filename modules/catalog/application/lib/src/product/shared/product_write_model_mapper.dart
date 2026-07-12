import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'package:vet45_catalog_application/src/product/queries/get_product_control_center/product_control_center_read_model.dart';

/// Rebuilds a [Product] aggregate for domain-first command handlers.
abstract final class ProductWriteModelMapper {
  static Product fromControlCenter({
    required String tenantId,
    required ProductControlCenterReadModel model,
  }) {
    final now = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final productId = ProductId(model.productId);
    return Product.reconstitute(
      id: productId,
      tenantId: TenantId(tenantId),
      referenceId: ProductReferenceId.fromProductId(productId),
      name: ProductName(model.name),
      status: model.businessStatus,
      readiness: ProductReadinessEvaluator.compute(model.facts),
      images: [
        for (var i = 0; i < model.images.length; i++)
          ProductImage(
            storageKey: model.images[i],
            slotId: 'slot_$i',
            url: model.images[i],
            isPrimary: i == 0,
            sortOrder: i,
          ),
      ],
      createdBy: 'system',
      createdAt: now,
      updatedBy: 'system',
      updatedAt: now,
      version: model.stockVersion ?? 1,
      commercialName: model.tradeName == null || model.tradeName!.trim().isEmpty
          ? null
          : ProductName(model.tradeName!),
      sku: model.sku == null || model.sku!.trim().isEmpty ? null : Sku(model.sku!),
      barcode: model.barcode == null || model.barcode!.trim().isEmpty
          ? null
          : Barcode(model.barcode!),
      description: model.description,
      note: model.note,
      baseUnit: model.baseUnitName == null || model.baseUnitName!.trim().isEmpty
          ? null
          : ProductBaseUnit(model.baseUnitName!),
    );
  }
}
