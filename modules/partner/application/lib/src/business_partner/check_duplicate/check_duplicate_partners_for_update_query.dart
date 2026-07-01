import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'partner_duplicate_match_dto.dart';

@RequiresPermission(PartnerPermissions.update)
@RequiresTenant()
final class CheckDuplicatePartnersForUpdateQuery extends QueryBase<List<PartnerDuplicateMatchDto>> {
  CheckDuplicatePartnersForUpdateQuery({
    String? id,
    required this.tenantId,
    required this.excludePartnerId,
    this.phone,
    this.email,
    this.taxCode,
  }) : super(id);

  final String tenantId;

  final String excludePartnerId;
  final String? phone;
  final String? email;
  final String? taxCode;
}
