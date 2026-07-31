import 'package:vet45_shared_application/application.dart';

import '../../dto/tenant_onboarding_operation_dto.dart';
import '../../ports/i_platform_admin_gateway.dart';
import '../../shared/iam_blocked_codes.dart';
import '../../shared/iam_blocked_exception.dart';
import 'get_tenant_onboarding_operation_query.dart';

@QueryHandlerFor(GetTenantOnboardingOperationQuery)
final class GetTenantOnboardingOperationQueryHandler
    implements
        IQueryHandler<
          GetTenantOnboardingOperationQuery,
          TenantOnboardingOperationDto
        > {
  GetTenantOnboardingOperationQueryHandler({
    required IPlatformAdminGateway platformGateway,
  }) : _platformGateway = platformGateway;

  final IPlatformAdminGateway _platformGateway;

  @override
  Future<TenantOnboardingOperationDto> handle(
    GetTenantOnboardingOperationQuery query,
  ) async {
    final result = await _platformGateway.getTenantOnboardingOperation(
      query.operationId,
    );
    if (result == null) {
      throw const IamBlockedException(IamBlockedCodes.resourceNotFound);
    }
    return result;
  }
}
