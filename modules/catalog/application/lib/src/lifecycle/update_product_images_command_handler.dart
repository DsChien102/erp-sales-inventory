import 'package:vet45_shared_application/application.dart';

import '../ports/i_product_command_gateway.dart';
import 'update_product_images_command.dart';
import 'update_product_images_result.dart';

@CommandHandlerFor(UpdateProductImagesCommand)
final class UpdateProductImagesCommandHandler
    implements ICommandHandler<UpdateProductImagesCommand, UpdateProductImagesResult> {
  UpdateProductImagesCommandHandler({
    required IProductCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final IProductCommandGateway _commandGateway;

  @override
  Future<UpdateProductImagesResult> handle(
    UpdateProductImagesCommand command,
  ) {
    return _commandGateway.updateProductImages(command);
  }
}
