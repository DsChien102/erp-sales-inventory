import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../enums/sales_order_lifecycle_status.dart';

final class CommercialSnapshotIsImmutableRule implements IBusinessRule {
  const CommercialSnapshotIsImmutableRule({
    required this.lifecycleStatus,
    required this.attemptingLineMutation,
  });

  final SalesOrderLifecycleStatus lifecycleStatus;
  final bool attemptingLineMutation;

  @override
  bool isBroken() =>
      attemptingLineMutation &&
      (lifecycleStatus == SalesOrderLifecycleStatus.completed ||
          lifecycleStatus == SalesOrderLifecycleStatus.cancelled);

  @override
  String get message => 'Committed commercial snapshot lines cannot be mutated.';
}
