import 'package:vet45_catalog_application/src/product/shared/product_image_upload_slot_dto.dart';
import 'package:vet45_catalog_application/src/product/commands/request_product_image_upload/request_product_image_upload_command.dart';
import 'package:vet45_catalog_application/src/product/commands/request_product_maintenance_image_upload/request_product_maintenance_image_upload_command.dart';

abstract interface class IProductImageUploadPort {
  Future<ProductImageUploadSlotDto> reserveUploadSlot(
    RequestProductImageUploadCommand command,
  );

  Future<ProductImageUploadSlotDto> reserveMaintenanceUploadSlot(
    RequestProductMaintenanceImageUploadCommand command,
  );
}
