import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class CustomerPriceRuleKeyMustBeCompleteRule implements IBusinessRule {
  const CustomerPriceRuleKeyMustBeCompleteRule(this.parts);

  final List<String> parts;

  @override
  bool isBroken() => parts.any((part) => part.trim().isEmpty);

  @override
  String get message => 'Customer price rule key must be complete.';
}
