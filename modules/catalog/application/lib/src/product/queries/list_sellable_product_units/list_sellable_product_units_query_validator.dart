import 'package:vet45_shared_application/application.dart';

import 'list_sellable_product_units_query.dart';

final class ListSellableProductUnitsQueryValidator
    implements ICommandValidator<ListSellableProductUnitsQuery> {
  @override
  Future<void> validate(ListSellableProductUnitsQuery query) async {
    if (query.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (query.storeId.trim().isEmpty) {
      throw ValidationException('Store id is required.');
    }
    if (query.productId.trim().isEmpty) {
      throw ValidationException('Product id is required.');
    }
  }
}
