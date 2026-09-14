/// Filters inside SG-07 "Bộ lọc đơn hàng" sheet (Figma).
enum SalesOrderListTimeFilter { all, today, last7Days, last30Days }

enum SalesOrderListLifecycleFilter { all, completed, cancelled }

enum SalesOrderListSettlementFilter {
  all,
  paid,
  outstandingReceivable,
  unpaid,
}

enum SalesOrderListPostSaleFilter { all, hasReturnExchange }

enum SalesOrderListEInvoiceFilter { all, pending, issued }
