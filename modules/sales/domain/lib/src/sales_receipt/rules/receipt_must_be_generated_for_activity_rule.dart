import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../enums/sales_receipt_status.dart';

final class ReceiptMustBeGeneratedForActivityRule implements IBusinessRule {
  const ReceiptMustBeGeneratedForActivityRule(this.status);

  final SalesReceiptStatus status;

  @override
  bool isBroken() => status != SalesReceiptStatus.generated;

  @override
  String get message => 'Only a generated (non-archived) receipt can record distribution activity.';
}
