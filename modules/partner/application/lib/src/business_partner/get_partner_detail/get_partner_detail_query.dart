import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'partner_detail_dto.dart';

@RequiresPermission(PartnerPermissions.viewDetail)
@RequiresTenant()
final class GetPartnerDetailQuery extends QueryBase<PartnerDetailDto?> {
  GetPartnerDetailQuery({
    String? id,
    required this.tenantId,
    required this.partnerId,
  }) : super(id);

  final String tenantId;
  final String partnerId;
}
