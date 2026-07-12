import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/ports/i_product_command_gateway.dart';
import 'package:vet45_catalog_application/src/ports/i_product_write_port.dart';
import 'package:vet45_catalog_application/src/product/shared/change_product_business_status_result.dart';
import 'deactivate_product_command.dart';
import 'deactivate_product_command_validator.dart';

@CommandHandlerFor(DeactivateProductCommand)
final class DeactivateProductCommandHandler
    implements ICommandHandler<DeactivateProductCommand, ChangeProductBusinessStatusResult> {
  DeactivateProductCommandHandler({
    required IProductCommandGateway commandGateway,
    required IProductWritePort productWritePort,
    DeactivateProductCommandValidator? validator,
  }) : _commandGateway = commandGateway,
       _productWritePort = productWritePort,
       _validator = validator ?? DeactivateProductCommandValidator();

  final IProductCommandGateway _commandGateway;
  final IProductWritePort _productWritePort;
  final DeactivateProductCommandValidator _validator;

  @override
  Future<ChangeProductBusinessStatusResult> handle(
    DeactivateProductCommand command,
  ) async {
    await _validator.validate(command);
    final product = await _productWritePort.load(
      tenantId: command.tenantId,
      productId: command.productId,
    );
    if (product == null) {
      throw ApplicationException('Product not found');
    }
    product.deactivate(actorId: command.actorId);
    return _commandGateway.deactivateProduct(command);
  }
}
