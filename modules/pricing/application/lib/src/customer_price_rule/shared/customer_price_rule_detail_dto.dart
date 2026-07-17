import 'package:vet45_pricing_domain/domain.dart';

import 'customer_price_rule_derived_status.dart';
import 'customer_price_rule_reference_health_dto.dart';
import 'customer_price_rule_source_trace_dto.dart';
import 'customer_ref_dto.dart';
import 'effective_period_dto.dart';
import 'money_dto.dart';
import 'product_unit_ref_dto.dart';
import 'rule_validation_outcome_dto.dart';

final class CustomerPriceRuleDetailDto {
  const CustomerPriceRuleDetailDto({
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
    required this.referenceHealth,
    required this.sourceTrace,
    required this.createdBy,
    required this.createdAt,
    required this.updatedBy,
    required this.updatedAt,
    required this.version,
    required this.availableActions,
    this.note,
    this.disabledAt,
    this.disabledBy,
    this.disabledReason,
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
  final String? note;
  final RuleValidationOutcomeDto validationOutcome;
  final CustomerPriceRuleReferenceHealthDto referenceHealth;
  final CustomerPriceRuleSourceTraceDto sourceTrace;
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;
  final int version;
  final List<String> availableActions;
  final DateTime? disabledAt;
  final String? disabledBy;
  final String? disabledReason;
}
