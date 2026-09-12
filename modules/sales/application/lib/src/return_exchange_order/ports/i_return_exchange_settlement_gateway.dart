import '../../sales_order_settlement/commands/record_sales_payment/record_sales_payment_command.dart';
import '../../sales_order_settlement/commands/record_sales_refund/record_sales_refund_command.dart';
import '../../shared/return_exchange_settlement_result_dto.dart';
import '../../shared/sales_order_payment_summary_dto.dart';

/// Settlement mutations for return/exchange difference settlement (S33).
///
/// `recordPayment` resolves a unique stored return settlement plan by
/// tenant, sales order, and correlation id. Ambiguous or missing association
/// maps to `RETURN_EXCHANGE_BLOCKED`; it never guesses a return id.
abstract interface class IReturnExchangeSettlementGateway {
  Future<SalesOrderPaymentSummaryDto> recordPayment(
    RecordSalesPaymentCommand command,
  );

  Future<ReturnExchangeSettlementResultDto> recordRefund(
    RecordSalesRefundCommand command,
  );
}
