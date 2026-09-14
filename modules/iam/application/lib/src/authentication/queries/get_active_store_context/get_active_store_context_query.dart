import 'package:vet45_shared_application/application.dart';

import '../../shared/active_store_context_dto.dart';

/// Reads the authoritative active-store identity for the current principal.
@RequiresTenant()
final class GetActiveStoreContextQuery extends QueryBase<ActiveStoreContextDto>
    implements IQuery<ActiveStoreContextDto>, ITenantScopedCommand {
  GetActiveStoreContextQuery({
    String? id,
    required this.tenantId,
  }) : super(id);

  @override
  final String tenantId;
}
