import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/ports/i_product_change_history_gateway.dart';
import 'package:vet45_catalog_application/src/product_change_history/shared/product_change_history_result_dto.dart';
import 'get_product_change_history_query.dart';
import 'get_product_change_history_query_validator.dart';

@QueryHandlerFor(GetProductChangeHistoryQuery)
final class GetProductChangeHistoryQueryHandler
    implements IQueryHandler<GetProductChangeHistoryQuery, ProductChangeHistoryResultDto> {
  GetProductChangeHistoryQueryHandler({
    required IProductChangeHistoryGateway changeHistoryGateway,
    GetProductChangeHistoryQueryValidator? validator,
  }) : _changeHistoryGateway = changeHistoryGateway,
       _validator = validator ?? GetProductChangeHistoryQueryValidator();

  final IProductChangeHistoryGateway _changeHistoryGateway;
  final GetProductChangeHistoryQueryValidator _validator;

  @override
  Future<ProductChangeHistoryResultDto> handle(
    GetProductChangeHistoryQuery query,
  ) async {
    await _validator.validate(query);
    final page = await _changeHistoryGateway.listHistory(
      tenantId: query.tenantId,
      productId: query.productId,
      limit: query.limit,
      offset: query.offset,
      changeCategories: query.changeCategories,
    );

    return ProductChangeHistoryResultDto(
      productId: query.productId,
      items: page.items.map((row) => row.toDto()).toList(growable: false),
      totalCount: page.totalCount,
    );
  }
}
