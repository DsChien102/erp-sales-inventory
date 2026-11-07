import 'package:equatable/equatable.dart';
import 'package:erp/features/sales/data/models/sales_record_payment.dart';
import 'package:vet45_sales_application/application.dart';

enum SalesRecordPaymentStatus { editing, submitting, failure, succeeded }

final class SalesRecordPaymentState extends Equatable {
  const SalesRecordPaymentState({
    this.status = SalesRecordPaymentStatus.editing,
    this.amountMinor,
    this.method = SalesPaymentMethod.cash,
    this.externalReference = '',
    this.fieldError,
    this.errorMessage,
    this.canRetry = false,
    this.result,
  });

  final SalesRecordPaymentStatus status;
  final int? amountMinor;
  final SalesPaymentMethod method;
  final String externalReference;
  final String? fieldError;
  final String? errorMessage;
  final bool canRetry;
  final SalesRecordPaymentResult? result;

  SalesRecordPaymentState copyWith({
    SalesRecordPaymentStatus? status,
    int? Function()? amountMinor,
    SalesPaymentMethod? method,
    String? externalReference,
    String? Function()? fieldError,
    String? Function()? errorMessage,
    bool? canRetry,
    SalesRecordPaymentResult? Function()? result,
  }) {
    return SalesRecordPaymentState(
      status: status ?? this.status,
      amountMinor: amountMinor != null ? amountMinor() : this.amountMinor,
      method: method ?? this.method,
      externalReference: externalReference ?? this.externalReference,
      fieldError: fieldError != null ? fieldError() : this.fieldError,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      canRetry: canRetry ?? this.canRetry,
      result: result != null ? result() : this.result,
    );
  }

  @override
  List<Object?> get props => [
    status,
    amountMinor,
    method,
    externalReference,
    fieldError,
    errorMessage,
    canRetry,
    result,
  ];
}

