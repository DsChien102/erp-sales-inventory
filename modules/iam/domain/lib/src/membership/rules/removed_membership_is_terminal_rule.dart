import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../membership_status.dart';

final class RemovedMembershipIsTerminalRule implements IBusinessRule {
  const RemovedMembershipIsTerminalRule(this.status);

  final MembershipStatus status;

  @override
  bool isBroken() => status == MembershipStatus.removed;

  @override
  String get message => 'Removed membership is terminal';
}
