import 'package:equatable/equatable.dart';

import '../sales_order/sales_order_detail_vm.dart';

final class SalesOrderPaymentTransactionVm extends Equatable {
  const SalesOrderPaymentTransactionVm({
    required this.transactionId,
    required this.methodLabel,
    required this.amountMinor,
    required this.recordedAtFormatted,
    this.kindLabel,
    this.actorId,
  });

  final String transactionId;
  final String methodLabel;

  /// "Thu tiền" or "Hoàn tiền". Null when the row is not a product collection/refund.
  final String? kindLabel;
  final int amountMinor;
  final String recordedAtFormatted;
  final String? actorId;

  @override
  List<Object?> get props => [
    transactionId,
    methodLabel,
    kindLabel,
    amountMinor,
    recordedAtFormatted,
    actorId,
  ];
}

final class SalesOrderPaymentOriginalBreakdownVm extends Equatable {
  const SalesOrderPaymentOriginalBreakdownVm({
    required this.orderTotalMinor,
    required this.paidCashMinor,
    required this.paidBankMinor,
    required this.outstandingMinor,
  });

  final int orderTotalMinor;
  final int paidCashMinor;
  final int paidBankMinor;
  final int outstandingMinor;

  @override
  List<Object?> get props => [
    orderTotalMinor,
    paidCashMinor,
    paidBankMinor,
    outstandingMinor,
  ];
}

final class SalesOrderPaymentReturnSlipBreakdownVm extends Equatable {
  const SalesOrderPaymentReturnSlipBreakdownVm({
    required this.slipNumber,
    required this.customerPaysExtraMinor,
    this.paidCashExtraMinor = 0,
    this.paidBankExtraMinor = 0,
  });

  final String slipNumber;
  final int customerPaysExtraMinor;
  final int paidCashExtraMinor;
  final int paidBankExtraMinor;

  @override
  List<Object?> get props => [
    slipNumber,
    customerPaysExtraMinor,
    paidCashExtraMinor,
    paidBankExtraMinor,
  ];
}

final class SalesOrderPaymentVm extends Equatable {
  const SalesOrderPaymentVm({
    required this.orderTotalMinor,
    required this.paidTotalMinor,
    required this.outstandingMinor,
    required this.paidCashAmountMinor,
    required this.paidBankAmountMinor,
    required this.settlementStatus,
    required this.transactions,
    required this.hasMoreTransactions,
    this.dueDateFormatted,
    this.nextTransactionsCursor,
    this.transactionsLoadMoreError = false,
    this.originalOrderBreakdown,
    this.returnSlipBreakdowns = const [],
  });

  final int orderTotalMinor;
  final int paidTotalMinor;
  final int outstandingMinor;
  final int paidCashAmountMinor;
  final int paidBankAmountMinor;
  final String? dueDateFormatted;
  final SalesSettlementStatus settlementStatus;
  final List<SalesOrderPaymentTransactionVm> transactions;
  final bool hasMoreTransactions;
  final String? nextTransactionsCursor;
  final bool transactionsLoadMoreError;
  final SalesOrderPaymentOriginalBreakdownVm? originalOrderBreakdown;
  final List<SalesOrderPaymentReturnSlipBreakdownVm> returnSlipBreakdowns;

  bool get hasPostReturnBreakdown =>
      originalOrderBreakdown != null || returnSlipBreakdowns.isNotEmpty;

  String get settlementLabel => switch (settlementStatus) {
    SalesSettlementStatus.unpaid => 'Chưa thu',
    SalesSettlementStatus.partiallyPaid => 'Còn phải thu',
    SalesSettlementStatus.fullyPaid => 'Đã thanh toán',
    SalesSettlementStatus.partiallyRefunded => 'Hoàn một phần',
    SalesSettlementStatus.refunded => 'Đã hoàn',
    SalesSettlementStatus.noBalance => 'Đã tất toán',
  };

  SalesOrderPaymentVm copyWith({
    int? orderTotalMinor,
    int? paidTotalMinor,
    int? outstandingMinor,
    int? paidCashAmountMinor,
    int? paidBankAmountMinor,
    String? dueDateFormatted,
    bool clearDueDateFormatted = false,
    SalesSettlementStatus? settlementStatus,
    List<SalesOrderPaymentTransactionVm>? transactions,
    bool? hasMoreTransactions,
    String? nextTransactionsCursor,
    bool clearNextTransactionsCursor = false,
    bool? transactionsLoadMoreError,
    SalesOrderPaymentOriginalBreakdownVm? originalOrderBreakdown,
    bool clearOriginalOrderBreakdown = false,
    List<SalesOrderPaymentReturnSlipBreakdownVm>? returnSlipBreakdowns,
  }) {
    return SalesOrderPaymentVm(
      orderTotalMinor: orderTotalMinor ?? this.orderTotalMinor,
      paidTotalMinor: paidTotalMinor ?? this.paidTotalMinor,
      outstandingMinor: outstandingMinor ?? this.outstandingMinor,
      paidCashAmountMinor: paidCashAmountMinor ?? this.paidCashAmountMinor,
      paidBankAmountMinor: paidBankAmountMinor ?? this.paidBankAmountMinor,
      dueDateFormatted: clearDueDateFormatted ? null : (dueDateFormatted ?? this.dueDateFormatted),
      settlementStatus: settlementStatus ?? this.settlementStatus,
      transactions: transactions ?? this.transactions,
      hasMoreTransactions: hasMoreTransactions ?? this.hasMoreTransactions,
      nextTransactionsCursor: clearNextTransactionsCursor
          ? null
          : (nextTransactionsCursor ?? this.nextTransactionsCursor),
      transactionsLoadMoreError: transactionsLoadMoreError ?? this.transactionsLoadMoreError,
      originalOrderBreakdown: clearOriginalOrderBreakdown
          ? null
          : (originalOrderBreakdown ?? this.originalOrderBreakdown),
      returnSlipBreakdowns: returnSlipBreakdowns ?? this.returnSlipBreakdowns,
    );
  }

  @override
  List<Object?> get props => [
    orderTotalMinor,
    paidTotalMinor,
    outstandingMinor,
    paidCashAmountMinor,
    paidBankAmountMinor,
    dueDateFormatted,
    settlementStatus,
    transactions,
    hasMoreTransactions,
    nextTransactionsCursor,
    transactionsLoadMoreError,
    originalOrderBreakdown,
    returnSlipBreakdowns,
  ];
}

/// Data cho [SalesOrderDetailPaymentSummaryCard] ở trạng thái loaded.
/// Caller resolve theo tab context; widget chỉ render.
final class SalesOrderDetailPaymentDisplayData extends Equatable {
  const SalesOrderDetailPaymentDisplayData({
    required this.paidMinor,
    required this.outstandingMinor,
    required this.enabled,
  });

  final int paidMinor;
  final int outstandingMinor;

  /// `false` khi đơn hủy → muted style + không tap.
  final bool enabled;

  /// Gom logic paid/outstanding theo tab "Đơn gốc" / "Sau đổi/trả".
  factory SalesOrderDetailPaymentDisplayData.resolve({
    required bool isCancelled,
    required SalesOrderPaymentVm payment,
    required bool showCurrentHoldings,
    required int currentHoldingsTotal,
    required bool hasReturnSlips,
    required bool hasCurrentItems,
  }) {
    final int paidMinor;
    final int outstandingMinor;

    if (showCurrentHoldings && (hasCurrentItems || hasReturnSlips)) {
      final currentTotalMinor = currentHoldingsTotal > 0
          ? currentHoldingsTotal
          : payment.orderTotalMinor;
      paidMinor = payment.paidTotalMinor;
      outstandingMinor =
          (currentTotalMinor > paidMinor) ? (currentTotalMinor - paidMinor) : 0;
    } else if (payment.originalOrderBreakdown != null) {
      final breakdown = payment.originalOrderBreakdown!;
      paidMinor = breakdown.paidCashMinor + breakdown.paidBankMinor;
      outstandingMinor = breakdown.outstandingMinor;
    } else {
      paidMinor = payment.paidTotalMinor;
      outstandingMinor = payment.outstandingMinor;
    }

    return SalesOrderDetailPaymentDisplayData(
      paidMinor: paidMinor,
      outstandingMinor: outstandingMinor,
      enabled: !isCancelled,
    );
  }

  @override
  List<Object?> get props => [paidMinor, outstandingMinor, enabled];
}
