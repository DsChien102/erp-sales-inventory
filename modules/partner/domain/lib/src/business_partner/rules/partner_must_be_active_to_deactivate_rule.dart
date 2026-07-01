import '../../shared/partner_status.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class PartnerMustBeActiveToDeactivateRule implements IBusinessRule {
  PartnerMustBeActiveToDeactivateRule({required PartnerStatus status}) : _status = status;

  final PartnerStatus _status;

  @override
  bool isBroken() => _status != PartnerStatus.active;

  @override
  String get message => 'Partner must be active to deactivate.';
}
