import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class RuleCurrencyMustNotChangeRule implements IBusinessRule {
  const RuleCurrencyMustNotChangeRule({
    required this.currentCurrencyCode,
    required this.updatedCurrencyCode,
  });

  final String currentCurrencyCode;
  final String updatedCurrencyCode;

  @override
  bool isBroken() => currentCurrencyCode != updatedCurrencyCode;

  @override
  String get message => 'Customer price rule currency cannot be changed.';
}
