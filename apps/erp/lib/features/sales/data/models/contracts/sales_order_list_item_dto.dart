import 'customer_snapshot_dto.dart';
import 'money_dto.dart';
import 'sales_contract_enums.dart';
import 'store_snapshot_dto.dart';

final class SalesOrderListItemDto {
  const SalesOrderListItemDto({
    required this.salesOrderId,
    required this.orderNumber,
    required this.sourceVersion,
    required this.committedAt,
    required this.store,
    required this.total,
    required this.lifecycleStatus,
    required this.lockStatus,
    required this.settlementStatus,
    required this.returnStatus,
    required this.eInvoiceStatus,
    this.customer,
  });

  final String salesOrderId;
  final String orderNumber;
  final int sourceVersion;
  final DateTime committedAt;
  final CustomerSnapshotDto? customer;
  final StoreSnapshotDto store;
  final MoneyDto total;
  final SalesOrderLifecycleStatus lifecycleStatus;
  final SalesOrderLockStatus lockStatus;
  final SalesSettlementStatus settlementStatus;
  final SalesOrderReturnProjectionStatus returnStatus;
  final IntegrationDeliveryStatus eInvoiceStatus;
}
