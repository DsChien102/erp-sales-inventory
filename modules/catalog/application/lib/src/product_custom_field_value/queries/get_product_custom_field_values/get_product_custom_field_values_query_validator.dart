import 'package:vet45_shared_application/application.dart';

import 'get_product_custom_field_values_query.dart';

final class GetProductCustomFieldValuesQueryValidator
    implements ICommandValidator<GetProductCustomFieldValuesQuery> {
  @override
  Future<void> validate(GetProductCustomFieldValuesQuery query) async {
    if (query.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (query.productId.trim().isEmpty) {
      throw ValidationException('Product id is required.');
    }
  }
}
