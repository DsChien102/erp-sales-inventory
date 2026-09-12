import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_contract_base.dart';
import '../../../shared/sales_order_return_summary_dto.dart';

@RequiresPermission(SalesPermissions.viewReturnExchange)
@RequiresTenant()
final class GetReturnExchangeOrdersBySalesOrderQuery
    extends SalesReadContract<SalesOrderReturnSummaryDto> {
  GetReturnExchangeOrdersBySalesOrderQuery({
    super.id,
    super.tenantId,
    super.actorId,
    required this.salesOrderId,
    this.expectedSourceVersion,
  });

  final String salesOrderId;
  final int? expectedSourceVersion;

  GetReturnExchangeOrdersBySalesOrderQuery withExecutionContext({
    required String tenantId,
    String actorId = '',
  }) => GetReturnExchangeOrdersBySalesOrderQuery(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    salesOrderId: salesOrderId,
    expectedSourceVersion: expectedSourceVersion,
  );
}
