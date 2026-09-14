import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/cancellation_reason_policy_dto.dart';
import '../../../shared/sales_contract_base.dart';

@RequiresPermission(SalesPermissions.cancelOrder)
@RequiresTenant()
final class ListSalesOrderCancellationReasonsQuery
    extends SalesReadContract<List<CancellationReasonPolicyDto>> {
  ListSalesOrderCancellationReasonsQuery({
    super.id,
    super.tenantId,
    super.actorId,
  });

  ListSalesOrderCancellationReasonsQuery withExecutionContext({
    required String tenantId,
    String actorId = '',
  }) => ListSalesOrderCancellationReasonsQuery(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
  );
}
