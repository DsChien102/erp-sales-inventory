import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/ports/i_catalog_unit_gateway.dart';
import 'deactivate_product_conversion_unit_command.dart';
import 'deactivate_product_conversion_unit_command_validator.dart';
import 'package:vet45_catalog_application/src/product_unit/queries/list_product_units/list_product_units_query.dart';
import 'package:vet45_catalog_application/src/product_unit/shared/product_unit_domain_mapper.dart';
import 'package:vet45_catalog_application/src/product_unit/shared/product_unit_mutation_result.dart';

@CommandHandlerFor(DeactivateProductConversionUnitCommand)
final class DeactivateProductConversionUnitCommandHandler
    implements ICommandHandler<DeactivateProductConversionUnitCommand, ProductUnitMutationResult> {
  DeactivateProductConversionUnitCommandHandler({
    required ICatalogUnitGateway unitGateway,
    DeactivateProductConversionUnitCommandValidator? validator,
  }) : _unitGateway = unitGateway,
       _validator = validator ?? DeactivateProductConversionUnitCommandValidator();

  final ICatalogUnitGateway _unitGateway;
  final DeactivateProductConversionUnitCommandValidator _validator;

  @override
  Future<ProductUnitMutationResult> handle(
    DeactivateProductConversionUnitCommand command,
  ) async {
    await _validator.validate(command);
    final currentUnits = await _unitGateway.listProductUnits(
      query: ListProductUnitsQuery(
        tenantId: command.tenantId,
        productId: command.productId,
        includeInactive: true,
      ),
    );
    final unitSet = productUnitSetFromDto(currentUnits);
    unitSet.deactivateConversionUnit(command.productUnitId);

    return _unitGateway.deactivateConversionUnit(command: command);
  }
}
