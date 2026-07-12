import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/ports/i_catalog_custom_field_value_gateway.dart';
import 'get_product_custom_field_values_query.dart';
import 'get_product_custom_field_values_query_validator.dart';
import 'product_custom_field_values_dto.dart';

@QueryHandlerFor(GetProductCustomFieldValuesQuery)
final class GetProductCustomFieldValuesQueryHandler
    implements IQueryHandler<GetProductCustomFieldValuesQuery, ProductCustomFieldValuesDto> {
  GetProductCustomFieldValuesQueryHandler({
    required ICatalogCustomFieldValueGateway customFieldValueGateway,
    GetProductCustomFieldValuesQueryValidator? validator,
  }) : _customFieldValueGateway = customFieldValueGateway,
       _validator = validator ?? GetProductCustomFieldValuesQueryValidator();

  final ICatalogCustomFieldValueGateway _customFieldValueGateway;
  final GetProductCustomFieldValuesQueryValidator _validator;

  @override
  Future<ProductCustomFieldValuesDto> handle(
    GetProductCustomFieldValuesQuery query,
  ) async {
    await _validator.validate(query);
    return _customFieldValueGateway.getValues(
      tenantId: query.tenantId,
      productId: query.productId,
      includeInactiveValues: query.includeInactiveValues,
    );
  }
}
