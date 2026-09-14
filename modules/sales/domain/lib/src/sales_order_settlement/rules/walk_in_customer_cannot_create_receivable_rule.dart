import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../shared/value_objects/customer_ref_snapshot.dart';

final class WalkInCustomerCannotCreateReceivableRule implements IBusinessRule {
  const WalkInCustomerCannotCreateReceivableRule({
    required this.customer,
    required this.createsReceivable,
  });

  final CustomerRefSnapshot? customer;
  final bool createsReceivable;

  @override
  bool isBroken() => createsReceivable && (customer == null || customer!.isWalkIn);

  @override
  String get message => 'Walk-in or missing customer cannot create a receivable outstanding.';
}
