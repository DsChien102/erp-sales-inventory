import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_shared_application/application.dart';

import 'partner_duplicate_match_dto.dart';

@RequiresPermission('partner.create')
@RequiresTenant()
final class CheckDuplicatePartnersQuery
    extends QueryBase<List<PartnerDuplicateMatchDto>> {
  CheckDuplicatePartnersQuery({
    String? id,
    required this.tenantId,
    this.phone,
    this.email,
    this.taxCode,
    this.excludePartnerId,
  }) : super(id);

  final String tenantId;

  final String? phone;
  final String? email;
  final String? taxCode;
  final String? excludePartnerId;
}
