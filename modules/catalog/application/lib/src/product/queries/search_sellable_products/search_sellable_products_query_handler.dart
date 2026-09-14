import 'package:vet45_catalog_application/src/ports/i_catalog_sales_read_gateway.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/sellable_product_dto.dart';
import 'search_sellable_products_query.dart';
import 'search_sellable_products_query_validator.dart';

@QueryHandlerFor(SearchSellableProductsQuery)
final class SearchSellableProductsQueryHandler
    implements IQueryHandler<SearchSellableProductsQuery, List<SellableProductDto>> {
  SearchSellableProductsQueryHandler({
    required ICatalogSalesReadGateway readGateway,
    required SearchSellableProductsQueryValidator validator,
  }) : _readGateway = readGateway,
       _validator = validator;

  final ICatalogSalesReadGateway _readGateway;
  final SearchSellableProductsQueryValidator _validator;

  @override
  Future<List<SellableProductDto>> handle(
    SearchSellableProductsQuery query,
  ) async {
    await _validator.validate(query);
    return _readGateway.searchSellableProducts(
      tenantId: query.tenantId,
      storeId: query.storeId,
      keyword: query.keyword.trim(),
      limit: query.limit,
      offset: query.offset,
    );
  }
}
