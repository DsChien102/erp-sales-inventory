import '../../shared/sales_order_payment_summary_dto.dart';
import '../../shared/sales_order_result_dto.dart';
import '../../sales_order_settlement/queries/get_sales_order_payment_summary/get_sales_order_payment_summary_query.dart';
import '../queries/get_sales_order/get_sales_order_query.dart';

abstract interface class ISalesOrderReadGateway {
  Future<SalesOrderResultDto> getSalesOrder(GetSalesOrderQuery query);

  Future<SalesOrderPaymentSummaryDto> getPaymentSummary(
    GetSalesOrderPaymentSummaryQuery query,
  );
}
