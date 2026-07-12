import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/ports/i_product_command_gateway.dart';
import 'package:vet45_catalog_application/src/ports/i_product_write_port.dart';
import 'package:vet45_catalog_application/src/product/shared/change_product_business_status_result.dart';
import 'reactivate_product_command.dart';
import 'reactivate_product_command_validator.dart';

@CommandHandlerFor(ReactivateProductCommand)
final class ReactivateProductCommandHandler
    implements ICommandHandler<ReactivateProductCommand, ChangeProductBusinessStatusResult> {
  ReactivateProductCommandHandler({
    required IProductCommandGateway commandGateway,
    required IProductWritePort productWritePort,
    ReactivateProductCommandValidator? validator,
  }) : _commandGateway = commandGateway,
       _productWritePort = productWritePort,
       _validator = validator ?? ReactivateProductCommandValidator();

  final IProductCommandGateway _commandGateway;
  final IProductWritePort _productWritePort;
  final ReactivateProductCommandValidator _validator;

  @override
  Future<ChangeProductBusinessStatusResult> handle(
    ReactivateProductCommand command,
  ) async {
    await _validator.validate(command);
    final product = await _productWritePort.load(
      tenantId: command.tenantId,
      productId: command.productId,
    );
    if (product == null) {
      throw ApplicationException('Product not found');
    }
    product.reactivate(actorId: command.actorId);
    return _commandGateway.reactivateProduct(command);
  }
}
