import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/ports/i_product_image_upload_port.dart';
import 'package:vet45_catalog_application/src/product/shared/product_image_upload_slot_dto.dart';
import 'request_product_image_upload_command.dart';

@CommandHandlerFor(RequestProductImageUploadCommand)
final class RequestProductImageUploadCommandHandler
    implements ICommandHandler<RequestProductImageUploadCommand, ProductImageUploadSlotDto> {
  RequestProductImageUploadCommandHandler({
    required IProductImageUploadPort uploadPort,
  }) : _uploadPort = uploadPort;

  final IProductImageUploadPort _uploadPort;

  @override
  Future<ProductImageUploadSlotDto> handle(
    RequestProductImageUploadCommand command,
  ) {
    return _uploadPort.reserveUploadSlot(command);
  }
}
