import '../return_exchange_order/ports/i_return_exchange_settlement_gateway.dart';
import '../sales_order_settlement/commands/record_sales_payment/record_sales_payment_command.dart';
import '../sales_order_settlement/commands/record_sales_refund/record_sales_refund_command.dart';
import '../shared/money_dto.dart';
import '../shared/return_exchange_settlement_result_dto.dart';
import '../shared/sales_contract_enums.dart';
import '../shared/sales_order_payment_summary_dto.dart';

final class FakeReturnExchangeSettlementGateway implements IReturnExchangeSettlementGateway {
  FakeReturnExchangeSettlementGateway({
    SalesOrderPaymentSummaryDto? paymentResult,
    ReturnExchangeSettlementResultDto? refundResult,
    this.error,
  }) : _paymentResult = paymentResult,
       _refundResult = refundResult;

  final SalesOrderPaymentSummaryDto? _paymentResult;
  final ReturnExchangeSettlementResultDto? _refundResult;
  final Object? error;

  int recordPaymentCalls = 0;
  int recordRefundCalls = 0;

  RecordSalesPaymentCommand? lastPaymentCommand;
  RecordSalesRefundCommand? lastRefundCommand;

  @override
  Future<SalesOrderPaymentSummaryDto> recordPayment(
    RecordSalesPaymentCommand command,
  ) async {
    recordPaymentCalls += 1;
    lastPaymentCommand = command;
    if (error != null) throw error!;
    return _paymentResult ??
        SalesOrderPaymentSummaryDto(
          status: SalesSettlementStatus.partiallyPaid,
          orderTotal: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
          paidTotal: command.amount,
          outstandingTotal: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
        );
  }

  @override
  Future<ReturnExchangeSettlementResultDto> recordRefund(
    RecordSalesRefundCommand command,
  ) async {
    recordRefundCalls += 1;
    lastRefundCommand = command;
    if (error != null) throw error!;
    return _refundResult ??
        ReturnExchangeSettlementResultDto(
          returnExchangeId: command.returnExchangeId,
          difference: command.amount,
          status: SalesSettlementStatus.partiallyRefunded,
        );
  }
}
