import 'package:vet45_catalog_application/src/ports/i_catalog_sales_read_gateway.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/sellable_product_resolution_dto.dart';
import 'resolve_sellable_products_query.dart';
import 'resolve_sellable_products_query_validator.dart';

@QueryHandlerFor(ResolveSellableProductsQuery)
final class ResolveSellableProductsQueryHandler
    implements
        IQueryHandler<ResolveSellableProductsQuery,
            List<SellableProductResolutionDto>> {
  ResolveSellableProductsQueryHandler({
    required ICatalogSalesReadGateway readGateway,
    required ResolveSellableProductsQueryValidator validator,
  }) : _readGateway = readGateway,
       _validator = validator;

  final ICatalogSalesReadGateway _readGateway;
  final ResolveSellableProductsQueryValidator _validator;

  @override
  Future<List<SellableProductResolutionDto>> handle(
    ResolveSellableProductsQuery query,
  ) async {
    await _validator.validate(query);
    final requested = <String>[];
    for (final productId in query.productIds) {
      final trimmed = productId.trim();
      if (!requested.contains(trimmed)) {
        requested.add(trimmed);
      }
    }
    return _readGateway.resolveSellableProducts(
      tenantId: query.tenantId,
      storeId: query.storeId,
      productIds: requested,
    );
  }
}
