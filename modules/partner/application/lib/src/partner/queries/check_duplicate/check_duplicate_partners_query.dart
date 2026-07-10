import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'partner_duplicate_match_dto.dart';

@RequiresPermission(PartnerPermissions.create)
@RequiresTenant()
final class CheckDuplicatePartnersQuery
    extends QueryBase<List<PartnerDuplicateMatchDto>>
    implements IQuery<List<PartnerDuplicateMatchDto>>, ITenantScopedCommand {
  CheckDuplicatePartnersQuery({
    String? id,
    required this.tenantId,
    this.phone,
    this.email,
    this.taxCode,
    this.name,
    this.excludePartnerId,
  }) : super(id);

  @override
  final String tenantId;
  final String? phone;
  final String? email;
  final String? taxCode;
  final String? name;
  final String? excludePartnerId;
}
