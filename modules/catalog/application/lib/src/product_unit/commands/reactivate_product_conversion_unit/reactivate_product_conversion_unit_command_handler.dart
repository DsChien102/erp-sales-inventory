import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/ports/i_catalog_unit_gateway.dart';
import 'package:vet45_catalog_application/src/product_unit/queries/list_product_units/list_product_units_query.dart';
import 'package:vet45_catalog_application/src/product_unit/shared/product_unit_domain_mapper.dart';
import 'package:vet45_catalog_application/src/product_unit/shared/product_unit_mutation_result.dart';
import 'reactivate_product_conversion_unit_command.dart';
import 'reactivate_product_conversion_unit_command_validator.dart';

@CommandHandlerFor(ReactivateProductConversionUnitCommand)
final class ReactivateProductConversionUnitCommandHandler
    implements ICommandHandler<ReactivateProductConversionUnitCommand, ProductUnitMutationResult> {
  ReactivateProductConversionUnitCommandHandler({
    required ICatalogUnitGateway unitGateway,
    ReactivateProductConversionUnitCommandValidator? validator,
  }) : _unitGateway = unitGateway,
       _validator = validator ?? ReactivateProductConversionUnitCommandValidator();

  final ICatalogUnitGateway _unitGateway;
  final ReactivateProductConversionUnitCommandValidator _validator;

  @override
  Future<ProductUnitMutationResult> handle(
    ReactivateProductConversionUnitCommand command,
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
    unitSet.reactivateConversionUnit(command.productUnitId);

    return _unitGateway.reactivateConversionUnit(command: command);
  }
}
