import 'package:vet45_shared_application/application.dart';

import 'resolve_sellable_products_query.dart';

final class ResolveSellableProductsQueryValidator
    implements ICommandValidator<ResolveSellableProductsQuery> {
  @override
  Future<void> validate(ResolveSellableProductsQuery query) async {
    if (query.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (query.storeId.trim().isEmpty) {
      throw ValidationException('Store id is required.');
    }
    if (query.productIds.isEmpty) {
      throw ValidationException('At least one product id is required.');
    }
    if (query.productIds.length > ResolveSellableProductsQuery.maxProductIds) {
      throw ValidationException(
        'At most ${ResolveSellableProductsQuery.maxProductIds} product ids may '
        'be resolved in one request.',
      );
    }
    for (final productId in query.productIds) {
      if (productId.trim().isEmpty) {
        throw ValidationException('Product id is required.');
      }
    }
  }
}
