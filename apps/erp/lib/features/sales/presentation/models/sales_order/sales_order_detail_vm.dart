import 'package:equatable/equatable.dart';

enum SalesOrderLifecycleStatus { draft, committed, cancelled }

enum SalesSettlementStatus {
  unpaid,
  partiallyPaid,
  fullyPaid,
  partiallyRefunded,
  refunded,
  noBalance,
}

enum SalesEInvoiceStatus { notIssued, issuing, issued, sent, cancelled }

class SalesOrderDetailItemVm extends Equatable {
  const SalesOrderDetailItemVm({
    required this.lineId,
    required this.productName,
    required this.unitName,
    required this.quantity,
    required this.unitPriceMinor,
    required this.totalAmountMinor,
    this.originalUnitPriceMinor,
  });

  final String lineId;
  final String productName;
  final String unitName;
  final int quantity;
  final int unitPriceMinor;
  final int totalAmountMinor;
  final int? originalUnitPriceMinor;

  @override
  List<Object?> get props => [
    lineId,
    productName,
    unitName,
    quantity,
    unitPriceMinor,
    totalAmountMinor,
    originalUnitPriceMinor,
  ];
}

class SalesOrderDetailTimelineVm extends Equatable {
  const SalesOrderDetailTimelineVm({
    required this.title,
    required this.timestamp,
    required this.actorName,
    this.description,
    this.amountMinor,
  });

  final String title;
  final String timestamp;
  final String actorName;
  final String? description;
  final int? amountMinor;

  @override
  List<Object?> get props => [title, timestamp, actorName, description, amountMinor];
}

class SalesReturnExchangeSlipItemVm extends Equatable {
  const SalesReturnExchangeSlipItemVm({
    required this.returnExchangeId,
    required this.slipNumber,
    required this.typeText,
    required this.dateFormatted,
    required this.statusText,
    required this.diffText,
  });

  final String returnExchangeId;
  final String slipNumber;
  final String typeText;
  final String dateFormatted;
  final String statusText;
  final String diffText;

  @override
  List<Object?> get props => [
    returnExchangeId,
    slipNumber,
    typeText,
    dateFormatted,
    statusText,
    diffText,
  ];
}

class SalesOrderDetailVm extends Equatable {
  const SalesOrderDetailVm({
    required this.orderId,
    required this.orderNumber,
    required this.createdAtFormatted,
    required this.customerName,
    required this.customerPhone,
    required this.storeName,
    required this.totalAmountMinor,
    required this.paidAmountMinor,
    required this.lifecycleStatus,
    required this.settlementStatus,
    required this.eInvoiceStatus,
    required this.items,
    required this.timeline,
    this.currentItems = const [],
    this.sellerName = '',
    this.paidBankAmountMinor = 0,
    this.paidCashAmountMinor = 0,
    this.dueDateFormatted,
    this.cancelReason,
    this.cancelledBy,
    this.cancelledAtFormatted,
    this.returnExchangeSlips = const [],
    this.originalOrderTotalMinor,
    this.originalOrderPaidCashMinor,
    this.originalOrderPaidBankMinor,
    this.originalOrderRemainingMinor,
    this.returnSlipTotalAddedMinor,
    this.returnSlipPaidBankMinor,
    this.note,
    this.currentReceiptId,
  });

  final String orderId;
  final String orderNumber;
  final String createdAtFormatted;
  final String customerName;
  final String customerPhone;
  final String storeName;
  final String sellerName;
  final int totalAmountMinor;
  final int paidAmountMinor;
  final int paidBankAmountMinor;
  final int paidCashAmountMinor;
  final String? dueDateFormatted;
  final SalesOrderLifecycleStatus lifecycleStatus;
  final SalesSettlementStatus settlementStatus;
  final SalesEInvoiceStatus eInvoiceStatus;
  final List<SalesOrderDetailItemVm> items;
  // Derived "current holdings" lines after applying completed return/exchange
  // history on top of the original order lines (ADR-9, Phase 3b).
  final List<SalesOrderDetailItemVm> currentItems;
  final List<SalesOrderDetailTimelineVm> timeline;
  final String? cancelReason;
  final String? cancelledBy;
  final String? cancelledAtFormatted;
  final List<SalesReturnExchangeSlipItemVm> returnExchangeSlips;
  final int? originalOrderTotalMinor;
  final int? originalOrderPaidCashMinor;
  final int? originalOrderPaidBankMinor;
  final int? originalOrderRemainingMinor;
  final int? returnSlipTotalAddedMinor;
  final int? returnSlipPaidBankMinor;
  final String? note;
  final String? currentReceiptId;

  int get remainingReceivableMinor =>
      totalAmountMinor > paidAmountMinor ? totalAmountMinor - paidAmountMinor : 0;

  bool get isCancelled => lifecycleStatus == SalesOrderLifecycleStatus.cancelled;
  bool get hasReturnExchange => returnExchangeSlips.isNotEmpty;
  bool get canCancel => lifecycleStatus == SalesOrderLifecycleStatus.committed;
  bool get canReturnExchange => lifecycleStatus == SalesOrderLifecycleStatus.committed;

  @override
  List<Object?> get props => [
    orderId,
    orderNumber,
    createdAtFormatted,
    customerName,
    customerPhone,
    storeName,
    sellerName,
    totalAmountMinor,
    paidAmountMinor,
    paidBankAmountMinor,
    paidCashAmountMinor,
    dueDateFormatted,
    lifecycleStatus,
    settlementStatus,
    eInvoiceStatus,
    items,
    currentItems,
    timeline,
    cancelReason,
    cancelledBy,
    cancelledAtFormatted,
    returnExchangeSlips,
    originalOrderTotalMinor,
    originalOrderPaidCashMinor,
    originalOrderPaidBankMinor,
    originalOrderRemainingMinor,
    returnSlipTotalAddedMinor,
    returnSlipPaidBankMinor,
    note,
    currentReceiptId,
  ];
}
