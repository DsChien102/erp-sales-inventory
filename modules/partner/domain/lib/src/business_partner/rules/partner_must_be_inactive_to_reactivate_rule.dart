import '../../shared/partner_status.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class PartnerMustBeInactiveToReactivateRule implements IBusinessRule {
  PartnerMustBeInactiveToReactivateRule({required PartnerStatus status}) : _status = status;

  final PartnerStatus _status;

  @override
  bool isBroken() => _status != PartnerStatus.inactive;

  @override
  String get message => 'Partner must be inactive to reactivate.';
}
