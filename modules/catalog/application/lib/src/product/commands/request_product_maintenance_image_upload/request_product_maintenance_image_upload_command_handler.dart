import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/product/shared/product_image_upload_slot_dto.dart';
import 'package:vet45_catalog_application/src/ports/i_product_image_upload_port.dart';
import 'request_product_maintenance_image_upload_command.dart';

@CommandHandlerFor(RequestProductMaintenanceImageUploadCommand)
final class RequestProductMaintenanceImageUploadCommandHandler
    implements
        ICommandHandler<RequestProductMaintenanceImageUploadCommand, ProductImageUploadSlotDto> {
  RequestProductMaintenanceImageUploadCommandHandler({
    required IProductImageUploadPort uploadPort,
  }) : _uploadPort = uploadPort;

  final IProductImageUploadPort _uploadPort;

  @override
  Future<ProductImageUploadSlotDto> handle(
    RequestProductMaintenanceImageUploadCommand command,
  ) {
    return _uploadPort.reserveMaintenanceUploadSlot(command);
  }
}
