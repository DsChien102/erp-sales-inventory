import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'delete_eligibility_dto.dart';

@RequiresPermission(PartnerPermissions.delete)
@RequiresTenant()
final class CheckDeleteEligibilityQuery extends QueryBase<DeleteEligibilityDto>
    implements IQuery<DeleteEligibilityDto>, ITenantScopedCommand {
  CheckDeleteEligibilityQuery({
    String? id,
    required this.tenantId,
    required this.partnerId,
  }) : super(id);

  @override
  final String tenantId;
  final String partnerId;
}
