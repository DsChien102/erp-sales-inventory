import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/return_exchange_pricing_preview_dto.dart';
import '../../../shared/sales_contract_base.dart';

@RequiresPermission(SalesPermissions.createReturnExchange)
@RequiresTenant()
final class PreviewReturnExchangePricingQuery extends SalesReadContract<ReturnExchangePricingPreviewDto> {
  PreviewReturnExchangePricingQuery({
    super.id,
    super.tenantId,
    super.actorId,
    required this.salesOrderId,
    required this.lines,
  });

  final String salesOrderId;
  final List<ReturnExchangePricingLineInput> lines;

  PreviewReturnExchangePricingQuery withExecutionContext({
    required String tenantId,
    String actorId = '',
  }) => PreviewReturnExchangePricingQuery(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    salesOrderId: salesOrderId,
    lines: lines,
  );
}
