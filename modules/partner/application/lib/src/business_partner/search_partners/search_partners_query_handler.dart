import 'package:vet45_shared_application/application.dart';

import '../../ports/i_partner_read_gateway.dart';
import 'partner_search_result_dto.dart';
import 'search_partners_query.dart';

@QueryHandlerFor(SearchPartnersQuery)
final class SearchPartnersQueryHandler
    implements IQueryHandler<SearchPartnersQuery, PartnerSearchResultDto> {
  SearchPartnersQueryHandler({
    required IPartnerReadGateway readGateway,
  }) : _readGateway = readGateway;

  final IPartnerReadGateway _readGateway;

  @override
  Future<PartnerSearchResultDto> handle(SearchPartnersQuery query) {
    return _readGateway.search(
      tenantId: query.tenantId,
      criteria: query.criteria,
      limit: query.limit,
      offset: query.offset,
    );
  }
}
