import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class ProductMustNotBeSoftDeletedRule implements IBusinessRule {
  const ProductMustNotBeSoftDeletedRule(this.isSoftDeleted);

  final bool isSoftDeleted;

  @override
  bool isBroken() => isSoftDeleted;

  @override
  String get message => 'Product is soft-deleted and cannot be modified.';
}
