import 'money_dto.dart';
import 'sales_contract_enums.dart';
import 'sales_order_payment_original_breakdown_dto.dart';
import 'sales_order_payment_return_slip_breakdown_dto.dart';

final class SalesOrderPaymentSummaryDto {
  const SalesOrderPaymentSummaryDto({
    required this.status,
    required this.orderTotal,
    required this.paidTotal,
    required this.outstandingTotal,
    this.refundedTotal,
    this.netCollectedTotal,
    this.originalPayableTotal,
    this.adjustmentTotal,
    this.collectedCash,
    this.collectedBank,
    this.dueAt,
    this.originalOrder,
    this.returnSlips = const [],
  });

  final SalesSettlementStatus status;
  final MoneyDto orderTotal;

  /// Gross collected. Does not subtract refunds.
  final MoneyDto paidTotal;
  final MoneyDto outstandingTotal;
  final MoneyDto? refundedTotal;
  final MoneyDto? netCollectedTotal;
  final MoneyDto? originalPayableTotal;
  final MoneyDto? adjustmentTotal;

  /// All confirmed collections by method, including extra collections, not refunds.
  final MoneyDto? collectedCash;
  final MoneyDto? collectedBank;
  final DateTime? dueAt;
  final SalesOrderPaymentOriginalBreakdownDto? originalOrder;
  final List<SalesOrderPaymentReturnSlipBreakdownDto> returnSlips;
}
