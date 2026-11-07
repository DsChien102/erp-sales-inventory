import 'package:equatable/equatable.dart';
import 'package:erp/features/sales/data/models.dart';

import 'package:erp/features/sales/presentation/models/return_exchange_order/sales_return_exchange_settlement_vm.dart';

enum SalesReturnExchangeSettlementStatus {
  initial,
  loading,
  ready,
  blocked,
  stale,
  confirming,
  processing,
  success,
  retryableFailure,
  failure,
}

class SalesReturnExchangeSettlementState extends Equatable {
  const SalesReturnExchangeSettlementState({
    required this.orderId,
    required this.returnExchangeId,
    this.orderNumber = '',
    this.customerDisplayName = '',
    this.isWalkIn = false,
    this.draftVersion,
    this.settlement,
    this.valuation,
    this.blockers = const <SalesBlockerDto>[],
    this.screenError,
    this.status = SalesReturnExchangeSettlementStatus.initial,
    this.settledNowMinor,
    this.paymentDueDate,
    this.paymentMethod = SalesPaymentMethod.cash,
  });

  final String orderId;
  final String returnExchangeId;
  final String orderNumber;
  final String customerDisplayName;

  /// Source order has no identified customer; walk-ins must pay in full
  /// because a shortfall cannot become a receivable.
  final bool isWalkIn;
  final int? draftVersion;
  final SalesReturnExchangeSettlementVm? settlement;
  final ReturnExchangeValuationDto? valuation;
  final List<SalesBlockerDto> blockers;
  final String? screenError;
  final SalesReturnExchangeSettlementStatus status;

  /// Amount the customer settles right now (from the editable field).
  /// Null means "not edited yet" and is treated as the full collectable amount.
  final int? settledNowMinor;

  /// Payment due date chosen when a shortfall becomes customer debt.
  final DateTime? paymentDueDate;

  /// Method for the amount collected now.
  final SalesPaymentMethod paymentMethod;

  SalesReturnExchangeSettlementVm? get effectiveSettlement {
    final cached = settlement;
    if (cached != null) return cached;
    final plan = valuation?.settlementPlan;
    if (plan == null) return null;
    return SalesReturnExchangeSettlementVm(
      returnExchangeId: returnExchangeId,
      currencyCode: plan.currencyCode,
      netDifferenceMinor: plan.netDifferenceMinor,
      storeRefundMinor: plan.refundAmountMinor,
      customerCollectMinor: plan.collectAmountMinor,
      receivableCreateMinor: plan.receivableCreateAmountMinor,
      receivableReverseMinor: plan.receivableReverseAmountMinor,
      sourceOrderVersion: plan.sourceOrderVersion,
      sourceSettlementVersion: plan.sourceSettlementVersion,
      pricingSourceVersion: plan.pricingSourceVersion,
    );
  }

  /// Shortfall on a collect settlement that becomes customer debt, given the
  /// edited "settle now" amount. Refund flows never create this debt.
  int get outstandingCollectMinor {
    final s = effectiveSettlement;
    if (s == null || s.customerCollectMinor <= 0) return 0;
    final settled = settledNowMinor ?? s.customerCollectMinor;
    final remainder = s.customerCollectMinor - settled;
    return remainder > 0 ? remainder : 0;
  }

  /// A due date is mandatory once the customer leaves an outstanding balance.
  bool get requiresPaymentDueDate => outstandingCollectMinor > 0;

  bool get paymentInputsValid {
    if (!requiresPaymentDueDate) return true;
    return !isWalkIn && paymentDueDate != null;
  }

  bool get canConfirm =>
      effectiveSettlement != null &&
      paymentInputsValid &&
      (status == SalesReturnExchangeSettlementStatus.ready ||
          status == SalesReturnExchangeSettlementStatus.retryableFailure ||
          status == SalesReturnExchangeSettlementStatus.stale);

  SalesReturnExchangeSettlementState copyWith({
    String? orderNumber,
    String? customerDisplayName,
    bool? isWalkIn,
    int? draftVersion,
    SalesReturnExchangeSettlementVm? settlement,
    ReturnExchangeValuationDto? valuation,
    List<SalesBlockerDto>? blockers,
    String? screenError,
    SalesReturnExchangeSettlementStatus? status,
    bool clearScreenError = false,
    bool clearSettlement = false,
    int? settledNowMinor,
    DateTime? paymentDueDate,
    SalesPaymentMethod? paymentMethod,
    bool clearSettledNow = false,
    bool clearPaymentDueDate = false,
  }) {
    return SalesReturnExchangeSettlementState(
      orderId: orderId,
      returnExchangeId: returnExchangeId,
      orderNumber: orderNumber ?? this.orderNumber,
      customerDisplayName: customerDisplayName ?? this.customerDisplayName,
      isWalkIn: isWalkIn ?? this.isWalkIn,
      draftVersion: draftVersion ?? this.draftVersion,
      settlement: clearSettlement ? null : (settlement ?? this.settlement),
      valuation: valuation ?? this.valuation,
      blockers: blockers ?? this.blockers,
      screenError: clearScreenError ? null : (screenError ?? this.screenError),
      status: status ?? this.status,
      settledNowMinor: clearSettledNow ? null : (settledNowMinor ?? this.settledNowMinor),
      paymentDueDate: clearPaymentDueDate ? null : (paymentDueDate ?? this.paymentDueDate),
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  @override
  List<Object?> get props => [
    orderId,
    returnExchangeId,
    orderNumber,
    customerDisplayName,
    isWalkIn,
    draftVersion,
    settlement,
    valuation,
    blockers,
    screenError,
    status,
    settledNowMinor,
    paymentDueDate,
    paymentMethod,
  ];
}
