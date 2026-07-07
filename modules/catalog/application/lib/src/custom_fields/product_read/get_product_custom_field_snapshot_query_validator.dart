import 'package:vet45_shared_application/application.dart';

import 'get_product_custom_field_snapshot_query.dart';

final class GetProductCustomFieldSnapshotQueryValidator
    implements ICommandValidator<GetProductCustomFieldSnapshotQuery> {
  @override
  Future<void> validate(GetProductCustomFieldSnapshotQuery query) async {
    if (query.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant is required.');
    }
    if (query.productIds.isEmpty) {
      throw ValidationException('At least one product is required.');
    }
    if (query.productIds.any((id) => id.trim().isEmpty)) {
      throw ValidationException('Product id is required.');
    }
    if (query.productIds.length > 100) {
      throw ValidationException('At most 100 products can be read at once.');
    }
  }
}
