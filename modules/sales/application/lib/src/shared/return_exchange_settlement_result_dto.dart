import 'money_dto.dart';
import 'sales_contract_enums.dart';

final class ReturnExchangeSettlementResultDto {
  const ReturnExchangeSettlementResultDto({
    required this.returnExchangeId,
    required this.difference,
    required this.status,
  });

  final String returnExchangeId;
  final MoneyDto difference;
  final SalesSettlementStatus status;
}
