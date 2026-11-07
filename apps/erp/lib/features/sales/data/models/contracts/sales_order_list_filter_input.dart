import 'sales_contract_enums.dart';

final class SalesOrderListFilterInput {
  const SalesOrderListFilterInput({
    this.completedFrom,
    this.completedTo,
    this.storeId,
    this.sellerId,
    this.customerId,
    this.lifecycleStatus,
    this.lockStatus,
    this.settlementStatus,
    this.hasOutstandingReceivable,
    this.hasReturnExchange,
    this.eInvoiceStatus,
  });

  final DateTime? completedFrom;
  final DateTime? completedTo;
  final String? storeId;
  final String? sellerId;
  final String? customerId;
  final SalesOrderLifecycleStatus? lifecycleStatus;
  final SalesOrderLockStatus? lockStatus;
  final SalesSettlementStatus? settlementStatus;
  final bool? hasOutstandingReceivable;
  final bool? hasReturnExchange;
  final IntegrationDeliveryStatus? eInvoiceStatus;
}
