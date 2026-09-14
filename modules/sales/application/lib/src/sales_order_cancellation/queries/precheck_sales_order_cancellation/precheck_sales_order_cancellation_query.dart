import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_contract_base.dart';
import '../../../shared/cancellation_precheck_dto.dart';

@RequiresPermission(SalesPermissions.cancelOrder)
@RequiresTenant()
final class PrecheckSalesOrderCancellationQuery extends SalesReadContract<CancellationPrecheckDto> {
  PrecheckSalesOrderCancellationQuery({
    super.id,
    super.tenantId,
    super.actorId,
    required this.salesOrderId,
    this.expectedSourceVersion,
  });

  final String salesOrderId;
  final int? expectedSourceVersion;

  PrecheckSalesOrderCancellationQuery withExecutionContext({
    required String tenantId,
    String actorId = '',
  }) => PrecheckSalesOrderCancellationQuery(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    salesOrderId: salesOrderId,
    expectedSourceVersion: expectedSourceVersion,
  );
}
