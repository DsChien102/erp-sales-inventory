import 'package:vet45_shared_application/application.dart';

import 'get_product_price_band_snapshot_query.dart';

final class GetProductPriceBandSnapshotQueryValidator
    implements ICommandValidator<GetProductPriceBandSnapshotQuery> {
  @override
  Future<void> validate(GetProductPriceBandSnapshotQuery query) async {
    if (query.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant is required.');
    }
    if (query.items.isEmpty) {
      throw ValidationException('At least one item is required.');
    }
    if (query.items.length > 100) {
      throw ValidationException('At most 100 items can be read at once.');
    }

    final seen = <String>{};
    for (final item in query.items) {
      if (item.productId.trim().isEmpty) {
        throw ValidationException('Product id is required.');
      }
      if (item.productUnitId.trim().isEmpty) {
        throw ValidationException('Product unit id is required.');
      }
      final key = '${item.productId}:${item.productUnitId}';
      if (!seen.add(key)) {
        throw ValidationException('Duplicate product and unit pair is not allowed.');
      }
    }
  }
}
