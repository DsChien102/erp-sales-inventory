import 'package:vet45_shared_application/application.dart';

import '../ports/i_catalog_read_gateway.dart';
import 'product_search_result_dto.dart';
import 'search_products_query.dart';
import 'search_products_query_validator.dart';

@QueryHandlerFor(SearchProductsQuery)
final class SearchProductsQueryHandler
    implements IQueryHandler<SearchProductsQuery, ProductSearchResultDto> {
  SearchProductsQueryHandler({
    required ICatalogReadGateway readGateway,
    SearchProductsQueryValidator? validator,
  }) : _readGateway = readGateway,
       _validator = validator ?? SearchProductsQueryValidator();

  final ICatalogReadGateway _readGateway;
  final SearchProductsQueryValidator _validator;

  @override
  Future<ProductSearchResultDto> handle(SearchProductsQuery query) async {
    await _validator.validate(query);
    return _readGateway.search(
      tenantId: query.tenantId,
      criteria: query.criteria,
      limit: query.limit,
      offset: query.offset,
    );
  }
}
