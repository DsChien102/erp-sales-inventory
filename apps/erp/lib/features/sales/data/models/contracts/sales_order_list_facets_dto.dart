final class SalesOrderListFacetsDto {
  const SalesOrderListFacetsDto({
    required this.all,
    required this.outstandingReceivable,
    required this.eInvoicePending,
  });

  final int all;
  final int outstandingReceivable;
  final int eInvoicePending;
}
