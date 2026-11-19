import 'package:equatable/equatable.dart';

/// Khoá JSON theo TH-06 6.2.
enum ReceivableFilter { all, overdue }

enum ReceivableHistoryKind {
  customerCollection,
  orderCollection,
  offset,
  refund;

  static ReceivableHistoryKind fromWire(String? wire) => switch (wire) {
    'customer_collection' => customerCollection,
    'order_collection' => orderCollection,
    'offset' => offset,
    _ => refund,
  };
}

enum CollectionMethod { cash, manualBankTransfer }

int _int(Object? v) => (v as num?)?.toInt() ?? 0;

String? _str(Object? v) => v is String && v.isNotEmpty ? v : null;

DateTime? _date(Object? v) => v is String && v.isNotEmpty ? DateTime.parse(v) : null;

Map<String, dynamic> _map(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<Map<String, dynamic>> _list(Object? v) =>
    v is List ? [for (final e in v) _map(e)] : const [];

/// PT-07: tóm tắt công nợ của một khách (`get_customer_receivable_summary`).
class CustomerReceivableSummary extends Equatable {
  const CustomerReceivableSummary({
    required this.outstandingMinor,
    required this.openOrderCount,
    required this.maxOverdueDays,
  });

  factory CustomerReceivableSummary.fromJson(Map<String, dynamic> j) => CustomerReceivableSummary(
    outstandingMinor: _int(j['outstandingMinor']),
    openOrderCount: _int(j['openOrderCount']),
    maxOverdueDays: _int(j['maxOverdueDays']),
  );

  final int outstandingMinor;
  final int openOrderCount;
  final int maxOverdueDays;

  @override
  List<Object?> get props => [outstandingMinor, openOrderCount, maxOverdueDays];
}

class ReceivableSummary extends Equatable {
  const ReceivableSummary({
    required this.totalOutstandingMinor,
    required this.customerCount,
    required this.overdueCustomerCount,
    required this.overdueAmountMinor,
    required this.maxOverdueDays,
  });

  factory ReceivableSummary.fromJson(Map<String, dynamic> j) => ReceivableSummary(
    totalOutstandingMinor: _int(j['totalOutstandingMinor']),
    customerCount: _int(j['customerCount']),
    overdueCustomerCount: _int(j['overdueCustomerCount']),
    overdueAmountMinor: _int(j['overdueAmountMinor']),
    maxOverdueDays: _int(j['maxOverdueDays']),
  );

  final int totalOutstandingMinor;
  final int customerCount;
  final int overdueCustomerCount;
  final int overdueAmountMinor;
  final int maxOverdueDays;

  @override
  List<Object?> get props => [
    totalOutstandingMinor,
    customerCount,
    overdueCustomerCount,
    overdueAmountMinor,
    maxOverdueDays,
  ];
}

class CustomerReceivableRow extends Equatable {
  const CustomerReceivableRow({
    required this.customerId,
    required this.displayName,
    required this.phone,
    required this.isActive,
    required this.outstandingMinor,
    required this.openOrderCount,
    required this.overdueOrderCount,
    required this.overdueAmountMinor,
    required this.maxOverdueDays,
    required this.nextDueDate,
  });

  factory CustomerReceivableRow.fromJson(Map<String, dynamic> j) => CustomerReceivableRow(
    customerId: j['customerId'] as String,
    displayName: (j['displayName'] as String?) ?? '',
    phone: _str(j['phone']),
    isActive: j['isActive'] as bool? ?? true,
    outstandingMinor: _int(j['outstandingMinor']),
    openOrderCount: _int(j['openOrderCount']),
    overdueOrderCount: _int(j['overdueOrderCount']),
    overdueAmountMinor: _int(j['overdueAmountMinor']),
    maxOverdueDays: _int(j['maxOverdueDays']),
    nextDueDate: _date(j['nextDueDate']),
  );

  final String customerId;
  final String displayName;
  final String? phone;
  final bool isActive;
  final int outstandingMinor;
  final int openOrderCount;
  final int overdueOrderCount;
  final int overdueAmountMinor;
  final int maxOverdueDays;
  final DateTime? nextDueDate;

  @override
  List<Object?> get props => [
    customerId,
    displayName,
    phone,
    isActive,
    outstandingMinor,
    openOrderCount,
    overdueOrderCount,
    overdueAmountMinor,
    maxOverdueDays,
    nextDueDate,
  ];
}

class CustomerReceivablePage extends Equatable {
  const CustomerReceivablePage({
    required this.summary,
    required this.items,
    required this.nextCursor,
  });

  factory CustomerReceivablePage.fromJson(Map<String, dynamic> j) => CustomerReceivablePage(
    summary: ReceivableSummary.fromJson(_map(j['summary'])),
    items: [for (final e in _list(j['items'])) CustomerReceivableRow.fromJson(e)],
    nextCursor: _str(j['nextCursor']),
  );

  final ReceivableSummary summary;
  final List<CustomerReceivableRow> items;
  final String? nextCursor;

  @override
  List<Object?> get props => [summary, items, nextCursor];
}

class ReceivableCustomer extends Equatable {
  const ReceivableCustomer({
    required this.customerId,
    required this.displayName,
    required this.phone,
    required this.isActive,
  });

  factory ReceivableCustomer.fromJson(Map<String, dynamic> j) => ReceivableCustomer(
    customerId: j['customerId'] as String,
    displayName: (j['displayName'] as String?) ?? '',
    phone: _str(j['phone']),
    isActive: j['isActive'] as bool? ?? true,
  );

  final String customerId;
  final String displayName;
  final String? phone;
  final bool isActive;

  @override
  List<Object?> get props => [customerId, displayName, phone, isActive];
}

class OpenReceivableOrder extends Equatable {
  const OpenReceivableOrder({
    required this.salesOrderId,
    required this.orderCode,
    required this.completedAt,
    required this.payableMinor,
    required this.outstandingMinor,
    required this.dueDate,
    required this.overdueDays,
    required this.settlementVersion,
  });

  factory OpenReceivableOrder.fromJson(Map<String, dynamic> j) => OpenReceivableOrder(
    salesOrderId: j['salesOrderId'] as String,
    orderCode: (j['orderCode'] as String?) ?? '',
    completedAt: DateTime.parse(j['completedAt'] as String),
    payableMinor: _int(j['payableMinor']),
    outstandingMinor: _int(j['outstandingMinor']),
    dueDate: _date(j['dueDate']),
    overdueDays: _int(j['overdueDays']),
    settlementVersion: _int(j['settlementVersion']),
  );

  final String salesOrderId;
  final String orderCode;
  final DateTime completedAt;
  final int payableMinor;
  final int outstandingMinor;
  final DateTime? dueDate;
  final int overdueDays;
  final int settlementVersion;

  @override
  List<Object?> get props => [
    salesOrderId,
    orderCode,
    completedAt,
    payableMinor,
    outstandingMinor,
    dueDate,
    overdueDays,
    settlementVersion,
  ];
}

class CustomerReceivableDetail extends Equatable {
  const CustomerReceivableDetail({
    required this.customer,
    required this.outstandingMinor,
    required this.openOrderCount,
    required this.overdueOrderCount,
    required this.maxOverdueDays,
    required this.openOrders,
  });

  factory CustomerReceivableDetail.fromJson(Map<String, dynamic> j) => CustomerReceivableDetail(
    customer: ReceivableCustomer.fromJson(_map(j['customer'])),
    outstandingMinor: _int(j['outstandingMinor']),
    openOrderCount: _int(j['openOrderCount']),
    overdueOrderCount: _int(j['overdueOrderCount']),
    maxOverdueDays: _int(j['maxOverdueDays']),
    openOrders: [for (final e in _list(j['openOrders'])) OpenReceivableOrder.fromJson(e)],
  );

  final ReceivableCustomer customer;
  final int outstandingMinor;
  final int openOrderCount;
  final int overdueOrderCount;
  final int maxOverdueDays;

  /// Cũ trước (server xếp).
  final List<OpenReceivableOrder> openOrders;

  @override
  List<Object?> get props => [
    customer,
    outstandingMinor,
    openOrderCount,
    overdueOrderCount,
    maxOverdueDays,
    openOrders,
  ];
}

class HistoryAllocation extends Equatable {
  const HistoryAllocation({required this.orderCode, required this.amountMinor});

  factory HistoryAllocation.fromJson(Map<String, dynamic> j) => HistoryAllocation(
    orderCode: (j['orderCode'] as String?) ?? '',
    amountMinor: _int(j['amountMinor']),
  );

  final String orderCode;
  final int amountMinor;

  @override
  List<Object?> get props => [orderCode, amountMinor];
}

class ReceivableHistoryItem extends Equatable {
  const ReceivableHistoryItem({
    required this.kind,
    required this.occurredAt,
    required this.amountMinor,
    this.paymentMethodCode,
    this.externalReference,
    this.actorDisplayName,
    this.orderCode,
    this.sourceOrderCode,
    this.targetOrderCode,
    this.returnExchangeReference,
    this.allocations = const [],
  });

  factory ReceivableHistoryItem.fromJson(Map<String, dynamic> j) => ReceivableHistoryItem(
    kind: ReceivableHistoryKind.fromWire(j['kind'] as String?),
    occurredAt: DateTime.parse(j['occurredAt'] as String),
    amountMinor: _int(j['amountMinor']),
    paymentMethodCode: _str(j['paymentMethodCode']),
    externalReference: _str(j['externalReference']),
    actorDisplayName: _str(j['actorDisplayName']),
    orderCode: _str(j['orderCode']),
    sourceOrderCode: _str(j['sourceOrderCode']),
    targetOrderCode: _str(j['targetOrderCode']),
    returnExchangeReference: _str(j['returnExchangeReference']),
    allocations: [for (final e in _list(j['allocations'])) HistoryAllocation.fromJson(e)],
  );

  final ReceivableHistoryKind kind;
  final DateTime occurredAt;
  final int amountMinor;
  final String? paymentMethodCode;
  final String? externalReference;
  final String? actorDisplayName;
  final String? orderCode;
  final String? sourceOrderCode;
  final String? targetOrderCode;
  final String? returnExchangeReference;
  final List<HistoryAllocation> allocations;

  @override
  List<Object?> get props => [
    kind,
    occurredAt,
    amountMinor,
    paymentMethodCode,
    externalReference,
    actorDisplayName,
    orderCode,
    sourceOrderCode,
    targetOrderCode,
    returnExchangeReference,
    allocations,
  ];
}

class ReceivableHistoryPage extends Equatable {
  const ReceivableHistoryPage({required this.items, required this.nextCursor});

  factory ReceivableHistoryPage.fromJson(Map<String, dynamic> j) => ReceivableHistoryPage(
    items: [for (final e in _list(j['items'])) ReceivableHistoryItem.fromJson(e)],
    nextCursor: _str(j['nextCursor']),
  );

  final List<ReceivableHistoryItem> items;
  final String? nextCursor;

  @override
  List<Object?> get props => [items, nextCursor];
}

class CustomerCollectionRequest extends Equatable {
  const CustomerCollectionRequest({
    required this.customerId,
    required this.amountMinor,
    required this.method,
    required this.externalReference,
    required this.orderIds,
    required this.expectedOutstandingMinor,
    required this.idempotencyKey,
  });

  final String customerId;
  final int amountMinor;
  final CollectionMethod method;
  final String? externalReference;
  final List<String> orderIds;
  final int expectedOutstandingMinor;
  final String idempotencyKey;

  @override
  List<Object?> get props => [
    customerId,
    amountMinor,
    method,
    externalReference,
    orderIds,
    expectedOutstandingMinor,
    idempotencyKey,
  ];
}

class CustomerCollectionResult extends Equatable {
  const CustomerCollectionResult({required this.collectionId, required this.outstandingAfterMinor});

  factory CustomerCollectionResult.fromJson(Map<String, dynamic> j) => CustomerCollectionResult(
    collectionId: (j['collectionId'] as String?) ?? '',
    outstandingAfterMinor: _int(j['outstandingAfterMinor']),
  );

  final String collectionId;
  final int outstandingAfterMinor;

  @override
  List<Object?> get props => [collectionId, outstandingAfterMinor];
}
