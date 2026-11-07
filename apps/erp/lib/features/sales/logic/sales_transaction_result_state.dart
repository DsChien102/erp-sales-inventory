import 'package:equatable/equatable.dart';
import 'package:erp/features/sales/data/models.dart';

import 'package:erp/features/sales/presentation/models/sales_receipt/sales_receipt_operation_state.dart';
import 'package:erp/features/sales/logic/sales_transaction_result_issue.dart';

export 'package:erp/features/sales/presentation/models/sales_receipt/sales_receipt_operation_state.dart';
export 'package:erp/features/sales/logic/sales_transaction_result_issue.dart';

enum SalesTransactionResultStatus {
  initial,
  loading,
  uncertain,
  loaded,
  partial,
  failure,
}

class SalesTransactionResultState extends Equatable {
  const SalesTransactionResultState({
    this.status = SalesTransactionResultStatus.initial,
    this.result,
    this.checkout,
    this.order,
    this.payment,
    this.issues = const <SalesTransactionResultIssue>[],
    this.receipt = const SalesReceiptOperationState(),
  });

  final SalesTransactionResultStatus status;

  /// Present only when every S13 read completed successfully.
  final CheckoutResultViewDto? result;

  /// Individual committed reads remain available for a partial presentation.
  final CheckoutResultDto? checkout;
  final SalesOrderResultDto? order;
  final SalesOrderPaymentSummaryDto? payment;
  final List<SalesTransactionResultIssue> issues;
  final SalesReceiptOperationState receipt;

  bool get receiptError => receipt.status == SalesReceiptOperationStatus.error;

  @override
  List<Object?> get props => [
    status,
    result,
    checkout,
    order,
    payment,
    issues,
    receipt,
  ];
}
