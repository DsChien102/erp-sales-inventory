import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_contract_base.dart';
import '../../../shared/sales_order_result_dto.dart';

@RequiresPermission(SalesPermissions.viewOrder)
@RequiresTenant()
final class GetSalesOrderQuery extends SalesReadContract<SalesOrderResultDto> {
  GetSalesOrderQuery({
    super.id,
    super.tenantId,
    super.actorId,
    required this.salesOrderId,
  });

  final String salesOrderId;

  GetSalesOrderQuery withExecutionContext({
    required String tenantId,
    String actorId = '',
  }) => GetSalesOrderQuery(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    salesOrderId: salesOrderId,
  );
}
