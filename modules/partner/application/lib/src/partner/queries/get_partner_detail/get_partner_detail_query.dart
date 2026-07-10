import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'partner_detail_dto.dart';

@RequiresPermission(PartnerPermissions.detailView)
@RequiresTenant()
final class GetPartnerDetailQuery extends QueryBase<PartnerDetailDto>
    implements IQuery<PartnerDetailDto>, ITenantScopedCommand {
  GetPartnerDetailQuery({
    String? id,
    required this.tenantId,
    required this.partnerId,
  }) : super(id);

  @override
  final String tenantId;
  final String partnerId;
}
