import '../sales_order/ports/i_sales_order_read_gateway.dart';
import '../sales_order/queries/get_sales_order/get_sales_order_query.dart';
import '../sales_order_settlement/queries/get_sales_order_payment_summary/get_sales_order_payment_summary_query.dart';
import '../shared/money_dto.dart';
import '../shared/sales_contract_enums.dart';
import '../shared/sales_order_payment_summary_dto.dart';
import '../shared/sales_order_result_dto.dart';

final class FakeSalesOrderReadGateway implements ISalesOrderReadGateway {
  FakeSalesOrderReadGateway({
    required SalesOrderResultDto result,
    SalesOrderPaymentSummaryDto? paymentSummary,
    this.error,
  }) : _result = result,
       _paymentSummary = paymentSummary;

  final SalesOrderResultDto _result;
  final SalesOrderPaymentSummaryDto? _paymentSummary;
  final Object? error;

  int orderCalls = 0;
  int paymentCalls = 0;

  @override
  Future<SalesOrderResultDto> getSalesOrder(GetSalesOrderQuery query) async {
    orderCalls += 1;
    if (error != null) throw error!;
    return _result;
  }

  @override
  Future<SalesOrderPaymentSummaryDto> getPaymentSummary(
    GetSalesOrderPaymentSummaryQuery query,
  ) async {
    paymentCalls += 1;
    if (error != null) throw error!;
    return _paymentSummary ??
        const SalesOrderPaymentSummaryDto(
          status: SalesSettlementStatus.paid,
          orderTotal: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
          paidTotal: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
          outstandingTotal: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
        );
  }
}
