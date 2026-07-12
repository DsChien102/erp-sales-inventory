import 'package:vet45_shared_application/application.dart';

import 'search_products_query.dart';

final class SearchProductsQueryValidator implements ICommandValidator<SearchProductsQuery> {
  @override
  Future<void> validate(SearchProductsQuery query) async {
    if (query.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (query.limit < 1 || query.limit > 100) {
      throw ValidationException('Limit must be between 1 and 100.');
    }
    if (query.offset < 0) {
      throw ValidationException('Offset cannot be negative.');
    }
  }
}
