import 'package:vet45_partner_domain/domain.dart';

import '../business_partner/search_partners/partner_search_result_dto.dart';

abstract interface class IPartnerReadGateway {
  Future<PartnerSearchResultDto> search({
    required String tenantId,
    required PartnerSearchCriteria criteria,
    int limit = 100,
    int offset = 0,
  });
}
