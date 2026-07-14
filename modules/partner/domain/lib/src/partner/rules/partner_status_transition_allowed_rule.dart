import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../enums/partner_status.dart';

class PartnerStatusTransitionAllowedRule implements IBusinessRule {
  const PartnerStatusTransitionAllowedRule({
    required this.from,
    required this.to,
  });

  final PartnerStatus from;
  final PartnerStatus to;

  @override
  bool isBroken() {
    if (from == to) {
      return false;
    }
    final allowed = switch (from) {
      PartnerStatus.active => to == PartnerStatus.inactive ||
          to == PartnerStatus.deleted,
      PartnerStatus.inactive => to == PartnerStatus.active ||
          to == PartnerStatus.deleted,
      PartnerStatus.deleted => false,
    };
    return !allowed;
  }

  @override
  String get message => 'Status transition from $from to $to is not allowed';
}
