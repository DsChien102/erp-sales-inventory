import 'package:vet45_shared_application/application.dart';

import '../../dto/tenant_dto.dart';
import '../../ports/i_tenant_profile_read_gateway.dart';
import '../../shared/iam_blocked_codes.dart';
import '../../shared/iam_blocked_exception.dart';
import 'get_tenant_query.dart';

@QueryHandlerFor(GetTenantQuery)
final class GetTenantQueryHandler
    implements IQueryHandler<GetTenantQuery, TenantDto> {
  GetTenantQueryHandler({
    required ITenantProfileReadGateway readGateway,
  }) : _readGateway = readGateway;

  final ITenantProfileReadGateway _readGateway;

  @override
  Future<TenantDto> handle(GetTenantQuery query) async {
    final tenant = await _readGateway.getTenant(tenantId: query.tenantId);
    if (tenant == null) {
      throw const IamBlockedException(IamBlockedCodes.resourceNotFound);
    }
    return tenant;
  }
}
