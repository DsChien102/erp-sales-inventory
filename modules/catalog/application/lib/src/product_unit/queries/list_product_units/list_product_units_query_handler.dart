import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/ports/i_catalog_unit_gateway.dart';
import 'list_product_units_query.dart';
import 'list_product_units_query_validator.dart';
import 'package:vet45_catalog_application/src/product_unit/shared/product_units_dto.dart';

@QueryHandlerFor(ListProductUnitsQuery)
final class ListProductUnitsQueryHandler
    implements IQueryHandler<ListProductUnitsQuery, ProductUnitsDto> {
  ListProductUnitsQueryHandler({
    required ICatalogUnitGateway unitGateway,
    ListProductUnitsQueryValidator? validator,
  }) : _unitGateway = unitGateway,
       _validator = validator ?? ListProductUnitsQueryValidator();

  final ICatalogUnitGateway _unitGateway;
  final ListProductUnitsQueryValidator _validator;

  @override
  Future<ProductUnitsDto> handle(ListProductUnitsQuery query) async {
    await _validator.validate(query);
    return _unitGateway.listProductUnits(query: query);
  }
}
