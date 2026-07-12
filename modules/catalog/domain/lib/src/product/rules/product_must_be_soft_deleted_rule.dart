import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../product_business_status.dart';

final class ProductMustBeSoftDeletedRule implements IBusinessRule {
  const ProductMustBeSoftDeletedRule(this.status);

  final ProductBusinessStatus status;

  @override
  bool isBroken() => !status.isSoftDeleted;

  @override
  String get message => 'Product is not soft-deleted.';
}
