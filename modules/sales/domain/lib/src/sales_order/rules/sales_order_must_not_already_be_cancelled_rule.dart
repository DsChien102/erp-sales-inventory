import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../enums/sales_order_lifecycle_status.dart';

final class SalesOrderMustNotAlreadyBeCancelledRule implements IBusinessRule {
  const SalesOrderMustNotAlreadyBeCancelledRule(this.status);

  final SalesOrderLifecycleStatus status;

  @override
  bool isBroken() => status == SalesOrderLifecycleStatus.cancelled;

  @override
  String get message => 'Sales order is already cancelled.';
}
