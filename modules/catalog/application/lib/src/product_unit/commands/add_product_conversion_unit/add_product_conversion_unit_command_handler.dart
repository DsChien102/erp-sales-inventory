import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/ports/i_catalog_unit_gateway.dart';
import 'add_product_conversion_unit_command.dart';
import 'add_product_conversion_unit_command_validator.dart';
import 'package:vet45_catalog_application/src/product_unit/queries/list_product_units/list_product_units_query.dart';
import 'package:vet45_catalog_application/src/product_unit/shared/product_unit_domain_mapper.dart';
import 'package:vet45_catalog_application/src/product_unit/shared/product_unit_mutation_result.dart';

@CommandHandlerFor(AddProductConversionUnitCommand)
final class AddProductConversionUnitCommandHandler
    implements ICommandHandler<AddProductConversionUnitCommand, ProductUnitMutationResult> {
  AddProductConversionUnitCommandHandler({
    required ICatalogUnitGateway unitGateway,
    AddProductConversionUnitCommandValidator? validator,
  }) : _unitGateway = unitGateway,
       _validator = validator ?? AddProductConversionUnitCommandValidator();

  final ICatalogUnitGateway _unitGateway;
  final AddProductConversionUnitCommandValidator _validator;

  @override
  Future<ProductUnitMutationResult> handle(
    AddProductConversionUnitCommand command,
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
    unitSet.addConversionUnit(
      id: 'pending',
      name: command.unitName,
      conversionRateToBase: command.conversionRateToBase,
    );

    return _unitGateway.addConversionUnit(command: command);
  }
}
