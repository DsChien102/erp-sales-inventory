import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'product_image_upload_slot_dto.dart';

@RequiresPermission(CatalogPermissions.create)
@RequiresTenant()
final class RequestProductImageUploadCommand extends CommandBase<ProductImageUploadSlotDto>
    implements ICommand<ProductImageUploadSlotDto>, ITenantScopedCommand {
  RequestProductImageUploadCommand({
    String? id,
    required this.tenantId,
    required this.actorId,
    required this.fileName,
    required this.contentType,
    required this.byteSize,
  }) : super(id);

  @override
  final String tenantId;

  final String actorId;
  final String fileName;
  final String contentType;
  final int byteSize;
}
