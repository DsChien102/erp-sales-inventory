import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class PartnerMustHaveNoTransactionHistoryRule implements IBusinessRule {
  PartnerMustHaveNoTransactionHistoryRule({
    required bool hasTransactionHistory,
  }) : _hasTransactionHistory = hasTransactionHistory;

  final bool _hasTransactionHistory;

  @override
  bool isBroken() => _hasTransactionHistory;

  @override
  String get message =>
      'Partner cannot be deleted because it has related business data.';
}
