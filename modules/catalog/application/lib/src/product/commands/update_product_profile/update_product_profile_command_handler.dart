import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/ports/i_product_command_gateway.dart';
import 'package:vet45_catalog_application/src/ports/i_product_write_port.dart';
import 'update_product_profile_command.dart';
import 'update_product_profile_result.dart';

@CommandHandlerFor(UpdateProductProfileCommand)
final class UpdateProductProfileCommandHandler
    implements ICommandHandler<UpdateProductProfileCommand, UpdateProductProfileResult> {
  UpdateProductProfileCommandHandler({
    required IProductCommandGateway commandGateway,
    required IProductWritePort productWritePort,
  }) : _commandGateway = commandGateway,
       _productWritePort = productWritePort;

  final IProductCommandGateway _commandGateway;
  final IProductWritePort _productWritePort;

  @override
  Future<UpdateProductProfileResult> handle(
    UpdateProductProfileCommand command,
  ) async {
    final product = await _productWritePort.load(
      tenantId: command.tenantId,
      productId: command.productId,
    );
    if (product == null) {
      throw ApplicationException('Product not found');
    }

    product.updateProfile(
      name: ProductName(command.productName),
      actorId: command.actorId,
      commercialName: _optionalName(command.commercialName),
      sku: _optionalSku(command.sku),
      barcode: _optionalBarcode(command.barcode),
      description: command.description,
      note: command.note,
    );

    return _commandGateway.updateProductProfile(command);
  }

  ProductName? _optionalName(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return ProductName(trimmed);
  }

  Sku? _optionalSku(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return Sku(trimmed);
  }

  Barcode? _optionalBarcode(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return Barcode(trimmed);
  }
}
