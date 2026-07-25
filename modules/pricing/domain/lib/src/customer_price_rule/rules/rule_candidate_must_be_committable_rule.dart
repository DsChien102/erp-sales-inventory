import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../rule_validation_outcome.dart';

final class RuleCandidateMustBeCommittableRule implements IBusinessRule {
  const RuleCandidateMustBeCommittableRule(this.outcome);

  final RuleValidationOutcome outcome;

  @override
  bool isBroken() => outcome.isBlocked;

  @override
  String get message => 'Customer price rule candidate is blocked.';
}
