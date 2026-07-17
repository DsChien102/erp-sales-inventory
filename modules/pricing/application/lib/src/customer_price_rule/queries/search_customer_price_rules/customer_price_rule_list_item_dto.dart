import 'package:vet45_pricing_domain/domain.dart';

import '../../shared/customer_price_rule_derived_status.dart';
import '../../shared/customer_ref_dto.dart';
import '../../shared/effective_period_dto.dart';
import '../../shared/money_dto.dart';
import '../../shared/product_unit_ref_dto.dart';
import '../../shared/rule_validation_outcome_dto.dart';

final class CustomerPriceRuleListItemDto {
  const CustomerPriceRuleListItemDto({
    required this.id,
    required this.customer,
    required this.productUnit,
    required this.price,
    required this.effectivePeriod,
    required this.ruleType,
    required this.sourceType,
    required this.persistedStatus,
    required this.derivedStatus,
    required this.validationOutcome,
    required this.updatedAt,
  });

  final String id;
  final CustomerRefDto customer;
  final ProductUnitRefDto productUnit;
  final MoneyDto price;
  final EffectivePeriodDto effectivePeriod;
  final CustomerPriceRuleType ruleType;
  final CustomerPriceRuleSourceType sourceType;
  final CustomerPriceRuleStatus persistedStatus;
  final CustomerPriceRuleDerivedStatus derivedStatus;
  final RuleValidationOutcomeDto validationOutcome;
  final DateTime updatedAt;
}
