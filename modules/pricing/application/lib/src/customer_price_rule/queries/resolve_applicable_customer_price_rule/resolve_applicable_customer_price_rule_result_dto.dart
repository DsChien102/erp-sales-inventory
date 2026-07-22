import 'package:vet45_pricing_domain/domain.dart';

import '../../shared/effective_period_dto.dart';
import '../../shared/money_dto.dart';

final class ApplicableCustomerPriceRuleDto {
  const ApplicableCustomerPriceRuleDto({
    required this.ruleId,
    required this.price,
    required this.effectivePeriod,
    required this.sourceType,
    required this.version,
  });

  final String ruleId;
  final MoneyDto price;
  final EffectivePeriodDto effectivePeriod;
  final CustomerPriceRuleSourceType sourceType;
  final int version;
}

final class ResolveApplicableCustomerPriceRuleResultDto {
  const ResolveApplicableCustomerPriceRuleResultDto({this.rule});

  final ApplicableCustomerPriceRuleDto? rule;
}
