import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'issuance_readiness_dto.dart';

@RequiresPermission(EInvoicePermissions.issue)
@RequiresTenant()
final class GetIssuanceReadinessQuery extends QueryBase<IssuanceReadinessDto>
    implements IQuery<IssuanceReadinessDto>, ITenantScopedCommand {
  GetIssuanceReadinessQuery({
    String? id,
    required this.tenantId,
    required this.actorId,
    required this.salesOrderId,
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
  final String salesOrderId;
}
