import 'package:vet45_shared_application/application.dart';

import 'list_product_unit_price_bands_query.dart';

final class ListProductUnitPriceBandsQueryValidator
    implements ICommandValidator<ListProductUnitPriceBandsQuery> {
  @override
  Future<void> validate(ListProductUnitPriceBandsQuery query) async {
    if (query.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (query.productId.trim().isEmpty) {
      throw ValidationException('Product id is required.');
    }
  }
}
