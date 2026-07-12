import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/product/shared/product_image_upload_slot_dto.dart';

@RequiresPermission(CatalogPermissions.update)
@RequiresTenant()
final class RequestProductMaintenanceImageUploadCommand
    extends CommandBase<ProductImageUploadSlotDto>
    implements ICommand<ProductImageUploadSlotDto>, ITenantScopedCommand {
  RequestProductMaintenanceImageUploadCommand({
    String? id,
    required this.tenantId,
    required this.actorId,
    required this.productId,
    required this.fileName,
    required this.contentType,
    required this.byteSize,
  }) : super(id);

  @override
  final String tenantId;

  final String actorId;
  final String productId;
  final String fileName;
  final String contentType;
  final int byteSize;
}
