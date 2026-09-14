import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../enums/sales_order_lifecycle_status.dart';

final class SalesOrderMustBeCompletedForLockRule implements IBusinessRule {
  const SalesOrderMustBeCompletedForLockRule(this.status);

  final SalesOrderLifecycleStatus status;

  @override
  bool isBroken() => status != SalesOrderLifecycleStatus.completed;

  @override
  String get message => 'Only completed orders can change lock status.';
}
