import 'money_dto.dart';
import 'return_exchange_settlement_plan_dto.dart';

final class ReturnExchangeValuationDto {
  const ReturnExchangeValuationDto({
    required this.returnValue,
    required this.exchangeValue,
    required this.settlementDifference,
    required this.settlementPlan,
    required this.sourceOrderVersion,
    this.pricingSourceVersion,
  });

  final MoneyDto returnValue;
  final MoneyDto exchangeValue;
  final MoneyDto settlementDifference;
  final ReturnExchangeSettlementPlanDto settlementPlan;
  final int sourceOrderVersion;
  final int? pricingSourceVersion;
}
