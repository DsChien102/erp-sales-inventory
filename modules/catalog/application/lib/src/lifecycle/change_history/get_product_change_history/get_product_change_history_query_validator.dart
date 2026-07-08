import 'package:vet45_shared_application/application.dart';

import 'get_product_change_history_query.dart';

final class GetProductChangeHistoryQueryValidator
    implements ICommandValidator<GetProductChangeHistoryQuery> {
  @override
  Future<void> validate(GetProductChangeHistoryQuery query) async {
    if (query.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant is required.');
    }
    if (query.productId.trim().isEmpty) {
      throw ValidationException('Product id is required.');
    }
    if (query.limit < 1 || query.limit > 100) {
      throw ValidationException('Limit must be between 1 and 100.');
    }
    if (query.offset < 0) {
      throw ValidationException('Offset must be zero or greater.');
    }
  }
}
