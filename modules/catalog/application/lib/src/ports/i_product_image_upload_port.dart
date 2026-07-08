import '../guided_create/product_image_upload_slot_dto.dart';
import '../guided_create/request_product_image_upload_command.dart';
import '../lifecycle/request_product_maintenance_image_upload_command.dart';

abstract interface class IProductImageUploadPort {
  Future<ProductImageUploadSlotDto> reserveUploadSlot(
    RequestProductImageUploadCommand command,
  );

  Future<ProductImageUploadSlotDto> reserveMaintenanceUploadSlot(
    RequestProductMaintenanceImageUploadCommand command,
  );
}
