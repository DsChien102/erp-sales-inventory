import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../membership_status.dart';

final class MembershipStatusTransitionAllowedRule implements IBusinessRule {
  const MembershipStatusTransitionAllowedRule({
    required this.from,
    required this.to,
  });

  final MembershipStatus from;
  final MembershipStatus to;

  @override
  bool isBroken() {
    if (from == to) {
      return false;
    }
    final allowed = switch (from) {
      MembershipStatus.active =>
        to == MembershipStatus.inactive || to == MembershipStatus.removed,
      MembershipStatus.inactive =>
        to == MembershipStatus.active || to == MembershipStatus.removed,
      MembershipStatus.removed => false,
    };
    return !allowed;
  }

  @override
  String get message =>
      'Membership status transition from $from to $to is not allowed';
}
