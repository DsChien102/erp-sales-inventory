import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_contract_base.dart';
import '../../../shared/sales_order_settlement_dto.dart';

@RequiresPermission(SalesPermissions.viewPayment)
@RequiresTenant()
final class GetSalesOrderSettlementQuery extends SalesReadContract<SalesOrderSettlementDto> {
  GetSalesOrderSettlementQuery({
    super.id,
    super.tenantId,
    super.actorId,
    required this.salesOrderId,
    this.expectedSourceVersion,
  });

  final String salesOrderId;
  final int? expectedSourceVersion;

  GetSalesOrderSettlementQuery withExecutionContext({
    required String tenantId,
    String actorId = '',
  }) => GetSalesOrderSettlementQuery(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    salesOrderId: salesOrderId,
    expectedSourceVersion: expectedSourceVersion,
  );
}
