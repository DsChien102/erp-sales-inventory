import '../../return_exchange_order/queries/get_sales_order_return_summary/get_sales_order_return_summary_query.dart';
import '../../sales_order_settlement/queries/get_sales_order_payment_transactions/get_sales_order_payment_transactions_query.dart';
import '../../sales_order_settlement/queries/get_sales_order_settlement/get_sales_order_settlement_query.dart';
import '../../shared/paged_sales_order_list_dto.dart';
import '../../shared/sales_order_detail_dto.dart';
import '../../shared/sales_order_return_summary_dto.dart';
import '../../shared/sales_order_settlement_dto.dart';
import '../../shared/sales_order_timeline_dto.dart';
import '../../shared/sales_payment_transactions_dto.dart';
import '../queries/get_sales_order_detail/get_sales_order_detail_query.dart';
import '../queries/get_sales_order_timeline/get_sales_order_timeline_query.dart';
import '../queries/list_sales_orders/list_sales_orders_query.dart';
import '../queries/search_sales_orders/search_sales_orders_query.dart';

abstract interface class ISalesOrderInquiryGateway {
  Future<PagedSalesOrderListDto> listSalesOrders(ListSalesOrdersQuery query);

  Future<PagedSalesOrderListDto> searchSalesOrders(SearchSalesOrdersQuery query);

  Future<SalesOrderDetailDto> getSalesOrderDetail(GetSalesOrderDetailQuery query);

  Future<SalesOrderSettlementDto> getSettlement(GetSalesOrderSettlementQuery query);

  Future<SalesPaymentTransactionsDto> getPaymentTransactions(
    GetSalesOrderPaymentTransactionsQuery query,
  );

  Future<SalesOrderTimelineDto> getTimeline(GetSalesOrderTimelineQuery query);

  Future<SalesOrderReturnSummaryDto> getReturnSummary(
    GetSalesOrderReturnSummaryQuery query,
  );
}
