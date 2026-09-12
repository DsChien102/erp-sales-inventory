import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../value_objects/cancellation_precheck_snapshot.dart';

final class CancellationMustPassPrecheckRule implements IBusinessRule {
  const CancellationMustPassPrecheckRule(this.precheck);

  final CancellationPrecheckSnapshot precheck;

  @override
  bool isBroken() => !precheck.isConfirmable;

  @override
  String get message => 'Cancellation cannot be confirmed while precheck blockers remain.';
}
