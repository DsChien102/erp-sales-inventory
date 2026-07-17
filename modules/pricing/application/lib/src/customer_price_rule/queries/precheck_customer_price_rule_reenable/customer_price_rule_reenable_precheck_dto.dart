import '../../shared/rule_validation_outcome_dto.dart';

final class CustomerPriceRuleReenablePrecheckDto {
  const CustomerPriceRuleReenablePrecheckDto({
    required this.validationOutcome,
    required this.precheckToken,
    required this.ruleVersion,
    required this.businessDate,
  });

  final RuleValidationOutcomeDto validationOutcome;
  final String precheckToken;
  final int ruleVersion;
  final DateTime businessDate;
}
