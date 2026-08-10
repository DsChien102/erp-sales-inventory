import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/tenant_context_dto.dart';
import '../../../ports/i_iam_access_gateway.dart';
import '../../../ports/i_iam_session_port.dart';
import '../../../ports/i_platform_user_preference_port.dart';
import 'get_tenant_context_query.dart';

@QueryHandlerFor(GetTenantContextQuery)
final class GetTenantContextQueryHandler
    implements IQueryHandler<GetTenantContextQuery, TenantContextDto> {
  GetTenantContextQueryHandler({
    required IIamAccessGateway accessGateway,
    required IPlatformUserPreferencePort preferencePort,
    required IIamSessionPort sessionPort,
    required ICurrentTenant currentTenant,
  }) : _accessGateway = accessGateway,
       _preferencePort = preferencePort,
       _sessionPort = sessionPort,
       _currentTenant = currentTenant;

  final IIamAccessGateway _accessGateway;
  final IPlatformUserPreferencePort _preferencePort;
  final IIamSessionPort _sessionPort;
  final ICurrentTenant _currentTenant;

  @override
  Future<TenantContextDto> handle(GetTenantContextQuery query) async {
    if (query.bootstrapFromLastSelected) {
      final lastSelected = _trimToNull(
        await _preferencePort.getLastSelectedTenantId(),
      );
      final bootstrapTenantId =
          lastSelected ?? _trimToNull(_currentTenant.tenantId);
      if (bootstrapTenantId == null) {
        return const TenantContextDto(status: TenantContextStatus.none);
      }

      final context = await _accessGateway.getValidatedTenantContext(
        sessionTenantId: bootstrapTenantId,
      );

      // OQ-07: invalid preference → none (do not auto-pick another tenant).
      if (context.status != TenantContextStatus.valid ||
          context.tenantId == null) {
        return const TenantContextDto(status: TenantContextStatus.none);
      }

      await _sessionPort.establishAfterSignIn(tenantId: context.tenantId);
      if (lastSelected == null) {
        await _preferencePort.setLastSelectedTenantId(context.tenantId);
      }
      return context;
    }

    final currentTenantId = _currentTenant.tenantId;
    if (currentTenantId == null || currentTenantId.trim().isEmpty) {
      return const TenantContextDto(status: TenantContextStatus.none);
    }

    return _accessGateway.getValidatedTenantContext(
      sessionTenantId: currentTenantId,
    );
  }

  String? _trimToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
