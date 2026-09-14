import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_contract_base.dart';
import '../../../shared/available_post_sale_actions_dto.dart';

@RequiresPermission(SalesPermissions.viewOrder)
@RequiresTenant()
final class GetAvailablePostSaleActionsQuery
    extends SalesReadContract<AvailablePostSaleActionsDto> {
  GetAvailablePostSaleActionsQuery({
    super.id,
    super.tenantId,
    super.actorId,
    required this.salesOrderId,
    this.expectedSourceVersion,
  });

  final String salesOrderId;
  final int? expectedSourceVersion;

  GetAvailablePostSaleActionsQuery withExecutionContext({
    required String tenantId,
    String actorId = '',
  }) => GetAvailablePostSaleActionsQuery(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    salesOrderId: salesOrderId,
    expectedSourceVersion: expectedSourceVersion,
  );
}
