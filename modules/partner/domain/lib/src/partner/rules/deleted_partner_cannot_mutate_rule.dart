import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../enums/partner_status.dart';

class DeletedPartnerCannotMutateRule implements IBusinessRule {
  const DeletedPartnerCannotMutateRule(this.status);

  final PartnerStatus status;

  @override
  bool isBroken() => status == PartnerStatus.deleted;

  @override
  String get message => 'Deleted partner cannot be mutated';
}
