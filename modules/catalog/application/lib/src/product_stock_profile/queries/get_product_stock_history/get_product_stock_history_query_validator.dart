import 'package:vet45_shared_application/application.dart';

import 'get_product_stock_history_query.dart';

final class GetProductStockHistoryQueryValidator
    implements ICommandValidator<GetProductStockHistoryQuery> {
  @override
  Future<void> validate(GetProductStockHistoryQuery query) async {
    if (query.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (query.productId.trim().isEmpty) {
      throw ValidationException('Product id is required.');
    }
    if (query.limit <= 0) {
      throw ValidationException('Limit must be greater than zero.');
    }
  }
}
