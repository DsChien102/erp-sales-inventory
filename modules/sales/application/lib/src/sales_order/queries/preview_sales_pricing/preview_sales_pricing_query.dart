import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/pricing_preview_dto.dart';
import '../../../shared/sales_contract_base.dart';
import '../../../shared/sales_order_working_state_dto.dart';

@RequiresPermission(SalesPermissions.finalizeCheckout)
@RequiresTenant()
final class PreviewSalesPricingQuery extends SalesReadContract<PricingPreviewDto>
    implements IQuery<PricingPreviewDto>, ITenantScopedCommand {
  PreviewSalesPricingQuery({
    super.id,
    super.tenantId,
    super.actorId,
    required this.workingState,
  });

  final SalesOrderWorkingStateDto workingState;

  PreviewSalesPricingQuery withExecutionContext({
    required String tenantId,
    String actorId = '',
  }) => PreviewSalesPricingQuery(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    workingState: workingState,
  );
}
