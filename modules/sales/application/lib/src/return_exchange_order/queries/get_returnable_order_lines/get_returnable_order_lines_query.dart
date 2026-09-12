import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_contract_base.dart';
import '../../../shared/returnable_order_lines_dto.dart';

@RequiresPermission(SalesPermissions.viewReturnExchange)
@RequiresTenant()
final class GetReturnableOrderLinesQuery extends SalesReadContract<ReturnableOrderLinesDto> {
  GetReturnableOrderLinesQuery({
    super.id,
    super.tenantId,
    super.actorId,
    required this.salesOrderId,
    this.expectedSourceVersion,
  });

  final String salesOrderId;
  final int? expectedSourceVersion;

  GetReturnableOrderLinesQuery withExecutionContext({
    required String tenantId,
    String actorId = '',
  }) => GetReturnableOrderLinesQuery(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    salesOrderId: salesOrderId,
    expectedSourceVersion: expectedSourceVersion,
  );
}
