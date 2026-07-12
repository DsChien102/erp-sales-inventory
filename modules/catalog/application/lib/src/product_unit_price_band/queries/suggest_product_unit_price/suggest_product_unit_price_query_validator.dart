import 'package:vet45_shared_application/application.dart';

import 'suggest_product_unit_price_query.dart';

final class SuggestProductUnitPriceQueryValidator
    implements ICommandValidator<SuggestProductUnitPriceQuery> {
  @override
  Future<void> validate(SuggestProductUnitPriceQuery query) async {
    if (query.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (query.productId.trim().isEmpty) {
      throw ValidationException('Product id is required.');
    }
  }
}
