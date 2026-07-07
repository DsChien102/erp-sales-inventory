import 'package:vet45_shared_application/application.dart';

import 'check_product_deletion_eligibility_query.dart';

final class CheckProductDeletionEligibilityQueryValidator
    implements ICommandValidator<CheckProductDeletionEligibilityQuery> {
  @override
  Future<void> validate(CheckProductDeletionEligibilityQuery query) async {
    if (query.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (query.productId.trim().isEmpty) {
      throw ValidationException('Product id is required.');
    }
  }
}
