import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../enums/sales_order_cancellation_status.dart';

final class CancellationMustBeRequestedForConfirmRule implements IBusinessRule {
  const CancellationMustBeRequestedForConfirmRule(this.status);

  final SalesOrderCancellationStatus status;

  @override
  bool isBroken() =>
      status != SalesOrderCancellationStatus.requested &&
      status != SalesOrderCancellationStatus.validating;

  @override
  String get message => 'Cancellation can only be confirmed from requested/validating state.';
}
