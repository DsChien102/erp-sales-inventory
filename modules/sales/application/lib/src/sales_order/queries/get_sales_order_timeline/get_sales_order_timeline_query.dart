import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_contract_base.dart';
import '../../../shared/sales_order_timeline_dto.dart';

@RequiresPermission(SalesPermissions.viewOrderHistory)
@RequiresTenant()
final class GetSalesOrderTimelineQuery extends SalesReadContract<SalesOrderTimelineDto> {
  GetSalesOrderTimelineQuery({
    super.id,
    super.tenantId,
    super.actorId,
    required this.salesOrderId,
    this.expectedSourceVersion,
  });

  final String salesOrderId;
  final int? expectedSourceVersion;

  GetSalesOrderTimelineQuery withExecutionContext({
    required String tenantId,
    String actorId = '',
  }) => GetSalesOrderTimelineQuery(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    salesOrderId: salesOrderId,
    expectedSourceVersion: expectedSourceVersion,
  );
}
