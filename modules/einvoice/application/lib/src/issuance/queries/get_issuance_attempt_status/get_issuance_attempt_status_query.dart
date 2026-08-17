import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'issuance_attempt_status_dto.dart';

@RequiresPermission(EInvoicePermissions.issue)
@RequiresTenant()
final class GetIssuanceAttemptStatusQuery extends QueryBase<IssuanceAttemptStatusDto>
    implements IQuery<IssuanceAttemptStatusDto>, ITenantScopedCommand {
  GetIssuanceAttemptStatusQuery({
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
