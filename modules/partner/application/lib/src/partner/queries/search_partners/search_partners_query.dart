import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'partner_search_result_dto.dart';

@RequiresPermission(PartnerPermissions.view)
@RequiresTenant()
final class SearchPartnersQuery extends QueryBase<PartnerSearchResultDto>
    implements IQuery<PartnerSearchResultDto>, ITenantScopedCommand {
  SearchPartnersQuery({
    String? id,
    required this.tenantId,
    this.query,
    this.partnerType,
    this.role,
    this.status,
    this.page = 1,
    this.limit = 20,
    this.sort,
  }) : super(id);

  @override
  final String tenantId;
  final String? query;
  final PartnerType? partnerType;
  final PartnerRoleType? role;
  final PartnerStatus? status;
  final int page;
  final int limit;
  final String? sort;
}
