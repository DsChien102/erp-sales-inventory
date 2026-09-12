import 'package:vet45_catalog_application/src/ports/i_catalog_sales_read_gateway.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/sellable_product_unit_dto.dart';
import 'list_sellable_product_units_query.dart';
import 'list_sellable_product_units_query_validator.dart';

@QueryHandlerFor(ListSellableProductUnitsQuery)
final class ListSellableProductUnitsQueryHandler
    implements IQueryHandler<ListSellableProductUnitsQuery, List<SellableProductUnitDto>> {
  ListSellableProductUnitsQueryHandler({
    required ICatalogSalesReadGateway readGateway,
    required ListSellableProductUnitsQueryValidator validator,
  }) : _readGateway = readGateway,
       _validator = validator;

  final ICatalogSalesReadGateway _readGateway;
  final ListSellableProductUnitsQueryValidator _validator;

  @override
  Future<List<SellableProductUnitDto>> handle(
    ListSellableProductUnitsQuery query,
  ) async {
    await _validator.validate(query);
    return _readGateway.listSellableProductUnits(
      tenantId: query.tenantId,
      storeId: query.storeId,
      productId: query.productId,
    );
  }
}
