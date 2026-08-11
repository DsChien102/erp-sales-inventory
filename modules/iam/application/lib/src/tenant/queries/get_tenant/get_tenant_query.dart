import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/tenant_dto.dart';

@RequiresPermission(IamPermissions.tenantView)
@RequiresTenant()
final class GetTenantQuery extends QueryBase<TenantDto>
    implements IQuery<TenantDto>, ITenantScopedCommand {
  GetTenantQuery({
    String? id,
    required this.tenantId,
  }) : super(id);

  @override
  final String tenantId;
}
