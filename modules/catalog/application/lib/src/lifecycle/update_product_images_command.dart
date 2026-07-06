import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'product_image_mutation_input.dart';
import 'update_product_images_result.dart';

@RequiresPermission(CatalogPermissions.update)
@RequiresTenant()
final class UpdateProductImagesCommand extends CommandBase<UpdateProductImagesResult>
    implements ICommand<UpdateProductImagesResult>, ITenantScopedCommand {
  UpdateProductImagesCommand({
    String? id,
    required this.tenantId,
    required this.actorId,
    required this.productId,
    this.images = const [],
    this.expectedVersion,
  }) : super(id);

  @override
  final String tenantId;

  final String actorId;
  final String productId;
  final List<ProductImageMutationInput> images;
  final int? expectedVersion;
}
