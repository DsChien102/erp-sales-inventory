import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_issuance_profile_gateway.dart';
import 'get_issuance_profile_query.dart';
import 'issuance_profile_dto.dart';

@QueryHandlerFor(GetIssuanceProfileQuery)
final class GetIssuanceProfileQueryHandler
    implements IQueryHandler<GetIssuanceProfileQuery, IssuanceProfileDto> {
  GetIssuanceProfileQueryHandler({
    required IIssuanceProfileGateway profileGateway,
  }) : _profileGateway = profileGateway;

  final IIssuanceProfileGateway _profileGateway;

  @override
  Future<IssuanceProfileDto> handle(GetIssuanceProfileQuery query) {
    return _profileGateway.getProfile(
      tenantId: query.tenantId,
      actorId: query.actorId,
    );
  }
}
