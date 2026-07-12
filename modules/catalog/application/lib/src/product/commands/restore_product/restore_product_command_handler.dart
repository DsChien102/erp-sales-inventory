import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/ports/i_product_command_gateway.dart';
import 'package:vet45_catalog_application/src/ports/i_product_write_port.dart';
import 'package:vet45_catalog_application/src/product/shared/change_product_soft_delete_result.dart';
import 'restore_product_command.dart';
import 'restore_product_command_validator.dart';

@CommandHandlerFor(RestoreProductCommand)
final class RestoreProductCommandHandler
    implements ICommandHandler<RestoreProductCommand, ChangeProductSoftDeleteResult> {
  RestoreProductCommandHandler({
    required IProductCommandGateway commandGateway,
    required IProductWritePort productWritePort,
    RestoreProductCommandValidator? validator,
  }) : _commandGateway = commandGateway,
       _productWritePort = productWritePort,
       _validator = validator ?? RestoreProductCommandValidator();

  final IProductCommandGateway _commandGateway;
  final IProductWritePort _productWritePort;
  final RestoreProductCommandValidator _validator;

  @override
  Future<ChangeProductSoftDeleteResult> handle(
    RestoreProductCommand command,
  ) async {
    await _validator.validate(command);
    final product = await _productWritePort.load(
      tenantId: command.tenantId,
      productId: command.productId,
    );
    if (product == null) {
      throw ApplicationException('Product not found');
    }
    product.restore(actorId: command.actorId);
    return _commandGateway.restoreProduct(command);
  }
}
