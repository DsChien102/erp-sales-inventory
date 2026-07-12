import 'package:vet45_shared_application/application.dart';

import 'list_product_units_query.dart';

final class ListProductUnitsQueryValidator implements ICommandValidator<ListProductUnitsQuery> {
  @override
  Future<void> validate(ListProductUnitsQuery query) async {
    if (query.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (query.productId.trim().isEmpty) {
      throw ValidationException('Product id is required.');
    }
  }
}
