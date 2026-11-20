import 'money_dto.dart';
import 'sales_contract_enums.dart';

final class ReturnExchangeSummaryDto {
  const ReturnExchangeSummaryDto({
    required this.returnExchangeId,
    required this.referenceNumber,
    required this.status,
    required this.completedAt,
    required this.settlementDifference,
  });

  final String returnExchangeId;
  final String referenceNumber;
  final ReturnExchangeStatus status;
  final DateTime completedAt;
  final MoneyDto settlementDifference;
}
