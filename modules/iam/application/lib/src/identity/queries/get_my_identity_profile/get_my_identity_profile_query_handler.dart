import 'package:vet45_shared_application/application.dart';

import '../../ports/i_identity_self_service_gateway.dart';
import '../../shared/my_identity_profile_dto.dart';
import 'get_my_identity_profile_query.dart';

@QueryHandlerFor(GetMyIdentityProfileQuery)
final class GetMyIdentityProfileQueryHandler
    implements IQueryHandler<GetMyIdentityProfileQuery, MyIdentityProfileDto> {
  GetMyIdentityProfileQueryHandler({
    required IIdentitySelfServiceGateway identityGateway,
  }) : _identityGateway = identityGateway;

  final IIdentitySelfServiceGateway _identityGateway;

  @override
  Future<MyIdentityProfileDto> handle(GetMyIdentityProfileQuery query) {
    return _identityGateway.getMyIdentityProfile();
  }
}
