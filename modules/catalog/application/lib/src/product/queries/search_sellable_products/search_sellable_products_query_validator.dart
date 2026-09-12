import 'package:vet45_shared_application/application.dart';

import 'search_sellable_products_query.dart';

final class SearchSellableProductsQueryValidator
    implements ICommandValidator<SearchSellableProductsQuery> {
  @override
  Future<void> validate(SearchSellableProductsQuery query) async {
    if (query.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (query.storeId.trim().isEmpty) {
      throw ValidationException('Store id is required.');
    }
    if (query.limit < 1 || query.limit > 100) {
      throw ValidationException('Limit must be between 1 and 100.');
    }
    if (query.offset < 0) {
      throw ValidationException('Offset cannot be negative.');
    }
  }
}
