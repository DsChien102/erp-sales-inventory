import 'package:vet45_shared_application/application.dart';

import '../../ports/i_partner_read_gateway.dart';
import 'get_partner_detail_query.dart';
import 'partner_detail_dto.dart';

@QueryHandlerFor(GetPartnerDetailQuery)
final class GetPartnerDetailQueryHandler
    implements IQueryHandler<GetPartnerDetailQuery, PartnerDetailDto?> {
  GetPartnerDetailQueryHandler({
    required IPartnerReadGateway readGateway,
  }) : _readGateway = readGateway;

  final IPartnerReadGateway _readGateway;

  @override
  Future<PartnerDetailDto?> handle(GetPartnerDetailQuery query) async {
    return _readGateway.getDetail(
      tenantId: query.tenantId,
      partnerId: query.partnerId,
    );
  }
}
