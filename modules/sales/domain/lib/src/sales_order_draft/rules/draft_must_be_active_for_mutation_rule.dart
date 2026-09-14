import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../enums/sales_draft_status.dart';

final class DraftMustBeActiveForMutationRule implements IBusinessRule {
  const DraftMustBeActiveForMutationRule(this.status);

  final SalesDraftStatus status;

  @override
  bool isBroken() => status != SalesDraftStatus.active;

  @override
  String get message => 'Terminal draft cannot be mutated.';
}
