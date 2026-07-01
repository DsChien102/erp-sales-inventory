import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'partner_search_result_dto.dart';

@RequiresPermission('partner.view')
@RequiresTenant()
final class SearchPartnersQuery extends QueryBase<PartnerSearchResultDto> {
  SearchPartnersQuery({
    String? id,
    required this.tenantId,
    required this.criteria,
    this.limit = 100,
    this.offset = 0,
  }) : super(id);

  final String tenantId;
  final PartnerSearchCriteria criteria;
  final int limit;
  final int offset;
}
