import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_contract_base.dart';
import '../../../shared/sales_order_detail_dto.dart';

@RequiresPermission(SalesPermissions.viewOrder)
@RequiresTenant()
final class GetSalesOrderDetailQuery extends SalesReadContract<SalesOrderDetailDto> {
  GetSalesOrderDetailQuery({
    super.id,
    super.tenantId,
    super.actorId,
    required this.salesOrderId,
    this.expectedSourceVersion,
  });

  final String salesOrderId;
  final int? expectedSourceVersion;

  GetSalesOrderDetailQuery withExecutionContext({
    required String tenantId,
    String actorId = '',
  }) => GetSalesOrderDetailQuery(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    salesOrderId: salesOrderId,
    expectedSourceVersion: expectedSourceVersion,
  );
}
