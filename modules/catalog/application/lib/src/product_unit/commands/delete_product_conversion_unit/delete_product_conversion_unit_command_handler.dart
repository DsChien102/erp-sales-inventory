import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/ports/i_catalog_unit_gateway.dart';
import 'delete_product_conversion_unit_command.dart';
import 'delete_product_conversion_unit_command_validator.dart';
import 'package:vet45_catalog_application/src/product_unit/queries/list_product_units/list_product_units_query.dart';
import 'package:vet45_catalog_application/src/product_unit/shared/product_unit_domain_mapper.dart';

@CommandHandlerFor(DeleteProductConversionUnitCommand)
final class DeleteProductConversionUnitCommandHandler
    implements ICommandHandler<DeleteProductConversionUnitCommand, void> {
  DeleteProductConversionUnitCommandHandler({
    required ICatalogUnitGateway unitGateway,
    DeleteProductConversionUnitCommandValidator? validator,
  }) : _unitGateway = unitGateway,
       _validator = validator ?? DeleteProductConversionUnitCommandValidator();

  final ICatalogUnitGateway _unitGateway;
  final DeleteProductConversionUnitCommandValidator _validator;

  @override
  Future<void> handle(DeleteProductConversionUnitCommand command) async {
    await _validator.validate(command);
    final currentUnits = await _unitGateway.listProductUnits(
      query: ListProductUnitsQuery(
        tenantId: command.tenantId,
        productId: command.productId,
        includeInactive: true,
      ),
    );
    final unitSet = productUnitSetFromDto(currentUnits);
    unitSet.deleteConversionUnit(command.productUnitId);

    await _unitGateway.deleteConversionUnit(command: command);
  }
}
