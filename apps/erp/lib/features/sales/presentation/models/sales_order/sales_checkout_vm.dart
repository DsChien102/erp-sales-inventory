import 'package:equatable/equatable.dart';

enum SalesPaymentMode { cash, bankTransfer, mixed }

class SalesCheckoutVm extends Equatable {
  const SalesCheckoutVm({
    required this.runtimeDraftId,
    required this.provisionalTotalAmountMinor,
    this.backendGrandTotalMinor,
    this.customerName,
    this.customerPhone,
    this.isWalkIn = false,
    this.customerDebtMinor = 0,
    this.paymentMode = SalesPaymentMode.cash,
    this.cashPaidMinor = 0,
    this.bankPaidMinor = 0,
    this.note,
    this.transactionCode,
    this.dueDate,
  });

  final String runtimeDraftId;
  final int provisionalTotalAmountMinor;
  final int? backendGrandTotalMinor;
  final String? customerName;
  final String? customerPhone;
  final bool isWalkIn;
  final int customerDebtMinor;
  final SalesPaymentMode paymentMode;
  final int cashPaidMinor;
  final int bankPaidMinor;
  final String? note;
  final String? transactionCode;
  final DateTime? dueDate;

  int get displayedTotalAmountMinor => backendGrandTotalMinor ?? provisionalTotalAmountMinor;

  int get paidAmountMinor => cashPaidMinor + bankPaidMinor;

  int get changeAmountMinor =>
      paidAmountMinor > displayedTotalAmountMinor ? paidAmountMinor - displayedTotalAmountMinor : 0;

  int get remainingReceivableMinor =>
      displayedTotalAmountMinor > paidAmountMinor ? displayedTotalAmountMinor - paidAmountMinor : 0;

  bool get isFullyPaid => paidAmountMinor >= displayedTotalAmountMinor;

  bool get canEditCashAmount => !(isWalkIn && paymentMode == SalesPaymentMode.cash);

  bool get canEditBankAmount => !(isWalkIn && paymentMode == SalesPaymentMode.bankTransfer);

  bool get canFinalizePayment =>
      (!isWalkIn || paidAmountMinor == displayedTotalAmountMinor) &&
      (remainingReceivableMinor == 0 || dueDate != null);

  SalesCheckoutVm copyWith({
    String? runtimeDraftId,
    int? provisionalTotalAmountMinor,
    int? backendGrandTotalMinor,
    bool clearBackendGrandTotalMinor = false,
    String? customerName,
    String? customerPhone,
    bool? isWalkIn,
    int? customerDebtMinor,
    SalesPaymentMode? paymentMode,
    int? cashPaidMinor,
    int? bankPaidMinor,
    String? note,
    String? transactionCode,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) {
    return SalesCheckoutVm(
      runtimeDraftId: runtimeDraftId ?? this.runtimeDraftId,
      provisionalTotalAmountMinor: provisionalTotalAmountMinor ?? this.provisionalTotalAmountMinor,
      backendGrandTotalMinor: clearBackendGrandTotalMinor
          ? null
          : (backendGrandTotalMinor ?? this.backendGrandTotalMinor),
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      isWalkIn: isWalkIn ?? this.isWalkIn,
      customerDebtMinor: customerDebtMinor ?? this.customerDebtMinor,
      paymentMode: paymentMode ?? this.paymentMode,
      cashPaidMinor: cashPaidMinor ?? this.cashPaidMinor,
      bankPaidMinor: bankPaidMinor ?? this.bankPaidMinor,
      note: note ?? this.note,
      transactionCode: transactionCode ?? this.transactionCode,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
    );
  }

  @override
  List<Object?> get props => [
    runtimeDraftId,
    provisionalTotalAmountMinor,
    backendGrandTotalMinor,
    customerName,
    customerPhone,
    isWalkIn,
    customerDebtMinor,
    paymentMode,
    cashPaidMinor,
    bankPaidMinor,
    note,
    transactionCode,
    dueDate,
  ];
}
