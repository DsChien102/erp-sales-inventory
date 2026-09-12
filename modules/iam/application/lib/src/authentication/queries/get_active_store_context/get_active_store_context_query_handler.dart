import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_iam_access_gateway.dart';
import '../../shared/active_store_context_dto.dart';
import 'get_active_store_context_query.dart';

@QueryHandlerFor(GetActiveStoreContextQuery)
final class GetActiveStoreContextQueryHandler
    implements IQueryHandler<GetActiveStoreContextQuery, ActiveStoreContextDto> {
  GetActiveStoreContextQueryHandler({
    required IIamAccessGateway accessGateway,
  }) : _accessGateway = accessGateway;

  final IIamAccessGateway _accessGateway;

  @override
  Future<ActiveStoreContextDto> handle(
    GetActiveStoreContextQuery query,
  ) async {
    final tenantId = _requiredValue(query.tenantId);
    final context = await _accessGateway.getSessionContext(
      tenantId: tenantId,
    );
    if (context == null) {
      throw ApplicationException('ACTIVE_STORE_CONTEXT_INVALID');
    }

    final resolvedTenantId = _requiredValue(context.tenantId);
    if (resolvedTenantId != tenantId) {
      throw ApplicationException('ACTIVE_STORE_CONTEXT_INVALID');
    }

    return ActiveStoreContextDto(
      userId: _requiredValue(context.userId),
      tenantId: resolvedTenantId,
      storeId: _requiredValue(context.activeStoreId),
      storeCode: _requiredValue(context.activeStoreCode),
      displayName: _requiredValue(context.activeStoreDisplayName),
    );
  }

  String _requiredValue(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      throw ApplicationException('ACTIVE_STORE_CONTEXT_INVALID');
    }
    return trimmed;
  }
}
