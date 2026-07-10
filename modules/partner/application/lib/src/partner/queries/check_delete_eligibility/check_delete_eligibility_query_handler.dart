import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_partner_read_gateway.dart';
import 'check_delete_eligibility_query.dart';
import 'delete_eligibility_dto.dart';

@QueryHandlerFor(CheckDeleteEligibilityQuery)
final class CheckDeleteEligibilityQueryHandler
    implements IQueryHandler<CheckDeleteEligibilityQuery, DeleteEligibilityDto> {
  CheckDeleteEligibilityQueryHandler({required IPartnerReadGateway readGateway})
    : _readGateway = readGateway;

  final IPartnerReadGateway _readGateway;

  @override
  Future<DeleteEligibilityDto> handle(CheckDeleteEligibilityQuery query) {
    return _readGateway.checkDeleteEligibility(query);
  }
}
