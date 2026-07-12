import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class ProductMustBeSoftDeletedRule implements IBusinessRule {
  const ProductMustBeSoftDeletedRule(this.isSoftDeleted);

  final bool isSoftDeleted;

  @override
  bool isBroken() => !isSoftDeleted;

  @override
  String get message => 'Product is not soft-deleted.';
}
