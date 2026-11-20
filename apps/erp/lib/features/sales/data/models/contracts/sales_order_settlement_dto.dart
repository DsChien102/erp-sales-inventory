import 'money_dto.dart';
import 'sales_contract_enums.dart';

final class SalesOrderSettlementDto {
  const SalesOrderSettlementDto({
    required this.settlementId,
    required this.salesOrderId,
    required this.version,
    required this.status,
    required this.orderTotal,
    required this.paidTotal,
    required this.refundedTotal,
    required this.outstanding,
    this.dueAt,
  });

  final String settlementId;
  final String salesOrderId;
  final int version;
  final SalesSettlementStatus status;
  final MoneyDto orderTotal;
  final MoneyDto paidTotal;
  final MoneyDto refundedTotal;
  final MoneyDto outstanding;
  final DateTime? dueAt;
}
