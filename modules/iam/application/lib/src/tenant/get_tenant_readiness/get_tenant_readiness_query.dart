import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../dto/tenant_readiness_dto.dart';

@RequiresPermission(IamPermissions.tenantReadinessView)
@RequiresTenant()
final class GetTenantReadinessQuery extends QueryBase<TenantReadinessDto>
    implements IQuery<TenantReadinessDto>, ITenantScopedCommand {
  GetTenantReadinessQuery({
    String? id,
    required this.tenantId,
  }) : super(id);

  @override
  final String tenantId;
}
