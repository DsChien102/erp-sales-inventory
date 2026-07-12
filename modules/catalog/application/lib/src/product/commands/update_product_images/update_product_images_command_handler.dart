import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/ports/i_product_command_gateway.dart';
import 'package:vet45_catalog_application/src/ports/i_product_write_port.dart';
import 'update_product_images_command.dart';
import 'update_product_images_result.dart';

@CommandHandlerFor(UpdateProductImagesCommand)
final class UpdateProductImagesCommandHandler
    implements ICommandHandler<UpdateProductImagesCommand, UpdateProductImagesResult> {
  UpdateProductImagesCommandHandler({
    required IProductCommandGateway commandGateway,
    required IProductWritePort productWritePort,
  }) : _commandGateway = commandGateway,
       _productWritePort = productWritePort;

  final IProductCommandGateway _commandGateway;
  final IProductWritePort _productWritePort;

  @override
  Future<UpdateProductImagesResult> handle(
    UpdateProductImagesCommand command,
  ) async {
    final product = await _productWritePort.load(
      tenantId: command.tenantId,
      productId: command.productId,
    );
    if (product == null) {
      throw ApplicationException('Product not found');
    }

    product.replaceImages(
      images: command.images
          .map(
            (image) => ProductImage(
              storageKey: image.storageKey,
              slotId: image.slotId,
              url: image.url,
              isPrimary: image.isPrimary,
              sortOrder: image.sortOrder,
            ),
          )
          .toList(growable: false),
      actorId: command.actorId,
    );

    return _commandGateway.updateProductImages(command);
  }
}
