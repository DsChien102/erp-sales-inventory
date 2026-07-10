import 'package:vet45_shared_domain/shared_kernel_domain.dart';

class SoftDeleteRequiresNoTransactionsRule implements IBusinessRule {
  const SoftDeleteRequiresNoTransactionsRule(this.hasTransactions);

  final bool hasTransactions;

  @override
  bool isBroken() => hasTransactions;

  @override
  String get message => 'Partner cannot be deleted while transactions exist';
}
