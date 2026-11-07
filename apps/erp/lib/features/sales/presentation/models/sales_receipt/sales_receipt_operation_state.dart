import 'package:equatable/equatable.dart';
import 'package:vet45_sales_application/application.dart';

import 'package:erp/features/sales/logic/sales_transaction_result_issue.dart';

enum SalesReceiptOperationStatus {
  idle,
  generating,
  ready,
  printing,
  sharing,
  activityWarning,
  error,
}

enum SalesReceiptActivityKind { print, share }

class SalesReceiptOperationState extends Equatable {
  const SalesReceiptOperationState({
    this.status = SalesReceiptOperationStatus.idle,
    this.value,
    this.issue,
    this.activityKind,
  });

  final SalesReceiptOperationStatus status;
  final SalesReceiptDto? value;
  final SalesTransactionResultIssue? issue;
  final SalesReceiptActivityKind? activityKind;

  SalesReceiptDocumentDto get document => value!.document;
  bool get hasPrintActivityWarning =>
      status == SalesReceiptOperationStatus.activityWarning &&
      activityKind == SalesReceiptActivityKind.print;
  bool get hasShareActivityWarning =>
      status == SalesReceiptOperationStatus.activityWarning &&
      activityKind == SalesReceiptActivityKind.share;

  @override
  List<Object?> get props => [status, value, issue, activityKind];
}
