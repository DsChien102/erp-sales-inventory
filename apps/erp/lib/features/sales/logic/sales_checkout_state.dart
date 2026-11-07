import 'package:equatable/equatable.dart';
import 'package:erp/features/sales/data/models.dart';
import 'package:erp/features/sales/presentation/models/sales_order/sales_checkout_vm.dart';
import 'package:erp/features/sales/presentation/models/sales_order/sales_checkout_attempt_envelope.dart';

enum SalesCheckoutStatus {
  initial,
  prechecking,
  ready,
  blocked,
  failure,
}

enum SalesCheckoutAttemptStatus {
  idle,
  submitting,
  recovering,
  succeeded,
  blocked,
  conflict,
  failure,
}

class SalesCheckoutState extends Equatable {
  const SalesCheckoutState({
    required this.vm,
    this.status = SalesCheckoutStatus.initial,
    this.precheck,
    this.errorMessage,
    this.requestRevision = 0,
    this.attemptStatus = SalesCheckoutAttemptStatus.idle,
    this.attempt,
    this.checkoutResult,
    this.attemptErrorMessage,
  });

  final SalesCheckoutVm vm;
  final SalesCheckoutStatus status;
  final CheckoutPrecheckDto? precheck;
  final String? errorMessage;
  final int requestRevision;
  final SalesCheckoutAttemptStatus attemptStatus;
  final SalesCheckoutAttemptEnvelope? attempt;
  final CheckoutResultDto? checkoutResult;
  final String? attemptErrorMessage;

  SalesCheckoutState copyWith({
    SalesCheckoutVm? vm,
    SalesCheckoutStatus? status,
    CheckoutPrecheckDto? precheck,
    bool clearPrecheck = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    int? requestRevision,
    SalesCheckoutAttemptStatus? attemptStatus,
    SalesCheckoutAttemptEnvelope? attempt,
    bool clearAttempt = false,
    CheckoutResultDto? checkoutResult,
    bool clearCheckoutResult = false,
    String? attemptErrorMessage,
    bool clearAttemptErrorMessage = false,
  }) {
    return SalesCheckoutState(
      vm: vm ?? this.vm,
      status: status ?? this.status,
      precheck: clearPrecheck ? null : (precheck ?? this.precheck),
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      requestRevision: requestRevision ?? this.requestRevision,
      attemptStatus: attemptStatus ?? this.attemptStatus,
      attempt: clearAttempt ? null : (attempt ?? this.attempt),
      checkoutResult: clearCheckoutResult ? null : (checkoutResult ?? this.checkoutResult),
      attemptErrorMessage: clearAttemptErrorMessage
          ? null
          : (attemptErrorMessage ?? this.attemptErrorMessage),
    );
  }

  @override
  List<Object?> get props => [
    vm,
    status,
    precheck,
    errorMessage,
    requestRevision,
    attemptStatus,
    attempt,
    checkoutResult,
    attemptErrorMessage,
  ];
}
