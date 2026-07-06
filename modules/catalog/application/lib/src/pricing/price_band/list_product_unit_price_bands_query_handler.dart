import 'package:vet45_shared_application/application.dart';

import '../../ports/i_product_price_band_gateway.dart';
import '../../units/product_unit_dto.dart';
import 'list_product_unit_price_bands_query.dart';
import 'list_product_unit_price_bands_query_validator.dart';
import 'product_unit_price_bands_dto.dart';

@QueryHandlerFor(ListProductUnitPriceBandsQuery)
final class ListProductUnitPriceBandsQueryHandler
    implements IQueryHandler<ListProductUnitPriceBandsQuery, ProductUnitPriceBandsDto> {
  ListProductUnitPriceBandsQueryHandler({
    required IProductPriceBandGateway priceBandGateway,
    ListProductUnitPriceBandsQueryValidator? validator,
  }) : _priceBandGateway = priceBandGateway,
       _validator = validator ?? ListProductUnitPriceBandsQueryValidator();

  final IProductPriceBandGateway _priceBandGateway;
  final ListProductUnitPriceBandsQueryValidator _validator;

  @override
  Future<ProductUnitPriceBandsDto> handle(
    ListProductUnitPriceBandsQuery query,
  ) async {
    await _validator.validate(query);
    return _priceBandGateway.listProductUnitPriceBands(
      tenantId: query.tenantId,
      productId: query.productId,
    );
  }
}
