import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/ports/i_product_command_gateway.dart';
import 'package:vet45_catalog_application/src/ports/i_product_write_port.dart';
import 'package:vet45_catalog_application/src/product/shared/change_product_soft_delete_result.dart';
import 'delete_product_command.dart';
import 'delete_product_command_validator.dart';

@CommandHandlerFor(DeleteProductCommand)
final class DeleteProductCommandHandler
    implements ICommandHandler<DeleteProductCommand, ChangeProductSoftDeleteResult> {
  DeleteProductCommandHandler({
    required IProductCommandGateway commandGateway,
    required IProductWritePort productWritePort,
    DeleteProductCommandValidator? validator,
  }) : _commandGateway = commandGateway,
       _productWritePort = productWritePort,
       _validator = validator ?? DeleteProductCommandValidator();

  final IProductCommandGateway _commandGateway;
  final IProductWritePort _productWritePort;
  final DeleteProductCommandValidator _validator;

  @override
  Future<ChangeProductSoftDeleteResult> handle(
    DeleteProductCommand command,
  ) async {
    await _validator.validate(command);
    final product = await _productWritePort.load(
      tenantId: command.tenantId,
      productId: command.productId,
    );
    if (product == null) {
      throw ApplicationException('Product not found');
    }
    product.softDelete(actorId: command.actorId);
    return _commandGateway.deleteProduct(command);
  }
}
