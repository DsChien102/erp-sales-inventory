import 'package:equatable/equatable.dart';
import 'package:vet45_sales_application/application.dart';

/// Presentation row for SG-07. Enriched beyond frozen [SalesOrderDto] until
/// list-projection CONTRACT is reopened.
final class SalesOrderListItemVm extends Equatable {
  const SalesOrderListItemVm({
    required this.salesOrderId,
    required this.orderNumber,
    required this.sourceVersion,
    required this.completedAt,
    required this.customerLabel,
    required this.total,
    required this.lifecycleStatus,
    required this.lockStatus,
    required this.settlementStatus,
    this.customerPhone,
    this.storeLabel,
    this.hasReturnExchange = false,
    this.eInvoiceIssued = false,
  });

  final String salesOrderId;
  final String orderNumber;
  final int sourceVersion;
  final DateTime completedAt;
  final String customerLabel;
  final String? customerPhone;
  final String? storeLabel;
  final MoneyDto total;
  final SalesOrderLifecycleStatus lifecycleStatus;
  final SalesOrderLockStatus lockStatus;
  final SalesSettlementStatus settlementStatus;
  final bool hasReturnExchange;
  final bool eInvoiceIssued;

  bool get isCancelled => lifecycleStatus == SalesOrderLifecycleStatus.cancelled;

  bool get isOutstandingReceivable =>
      !isCancelled &&
      (settlementStatus == SalesSettlementStatus.unpaid ||
          settlementStatus == SalesSettlementStatus.partiallyPaid);

  bool get isUnpaidLike => isOutstandingReceivable;

  String get lifecycleLabel => switch (lifecycleStatus) {
    SalesOrderLifecycleStatus.completed => 'Hoàn tất',
    SalesOrderLifecycleStatus.cancelled => 'Đã hủy',
  };

  String get settlementLabel => switch (settlementStatus) {
    SalesSettlementStatus.paid => 'Đã thanh toán',
    SalesSettlementStatus.unpaid => 'Chưa thu',
    SalesSettlementStatus.partiallyPaid => 'Còn phải thu',
    SalesSettlementStatus.partiallyRefunded => 'Hoàn một phần',
    SalesSettlementStatus.refunded => 'Đã hoàn',
    SalesSettlementStatus.noBalance => 'Không còn phải thu',
  };

  /// Subtitle under customer name: `phone · store`.
  String? get metaLine {
    final phone = customerPhone?.trim();
    final store = storeLabel?.trim();
    if ((phone == null || phone.isEmpty) && (store == null || store.isEmpty)) {
      return null;
    }
    if (phone == null || phone.isEmpty) return store;
    if (store == null || store.isEmpty) return phone;
    return '$phone · $store';
  }

  @override
  List<Object?> get props => [
    salesOrderId,
    orderNumber,
    sourceVersion,
    completedAt,
    customerLabel,
    customerPhone,
    storeLabel,
    total.amountMinor,
    total.currencyCode,
    lifecycleStatus,
    lockStatus,
    settlementStatus,
    hasReturnExchange,
    eInvoiceIssued,
  ];
}
