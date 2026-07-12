import 'package:vet45_catalog_domain/domain.dart';

import 'package:vet45_catalog_application/src/product/commands/update_product_images/update_product_images_command.dart';
import 'package:vet45_catalog_application/src/product/commands/update_product_images/update_product_images_result.dart';
import 'package:vet45_catalog_application/src/product/shared/change_product_business_status_result.dart';
import 'package:vet45_catalog_application/src/product/shared/change_product_soft_delete_result.dart';
import 'package:vet45_catalog_application/src/product/commands/deactivate_product/deactivate_product_command.dart';
import 'package:vet45_catalog_application/src/product/commands/delete_product/delete_product_command.dart';
import 'package:vet45_catalog_application/src/product/commands/reactivate_product/reactivate_product_command.dart';
import 'package:vet45_catalog_application/src/product/commands/restore_product/restore_product_command.dart';
import 'package:vet45_catalog_application/src/product/commands/update_product_profile/update_product_profile_command.dart';
import 'package:vet45_catalog_application/src/product/commands/update_product_profile/update_product_profile_result.dart';

abstract interface class IProductCommandGateway {
  Future<String> create({
    required Product product,
    required String idempotencyKey,
  });

  Future<void> setBasicStockQuantityBase({
    required String productId,
    required String tenantId,
    required ProductStockProfile profile,
  });

  Future<void> setManualBasePrice({
    required String productId,
    required String tenantId,
    required ProductBasePriceProfile profile,
    String currency = 'VND',
  });

  Future<void> setInitialPriceBand({
    required String productId,
    required String tenantId,
    required ProductUnitPriceBand priceBand,
  });

  Future<UpdateProductProfileResult> updateProductProfile(
    UpdateProductProfileCommand command,
  );

  Future<UpdateProductImagesResult> updateProductImages(
    UpdateProductImagesCommand command,
  );

  Future<ChangeProductBusinessStatusResult> deactivateProduct(
    DeactivateProductCommand command,
  );

  Future<ChangeProductBusinessStatusResult> reactivateProduct(
    ReactivateProductCommand command,
  );

  Future<ChangeProductSoftDeleteResult> deleteProduct(
    DeleteProductCommand command,
  );

  Future<ChangeProductSoftDeleteResult> restoreProduct(
    RestoreProductCommand command,
  );
}
