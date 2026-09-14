import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/sales_pricing_line_input.dart';
import '../../shared/sales_working_state_pricing_preview_dto.dart';

@RequiresPermission(PricingPermissions.previewSalesPricing)
@RequiresTenant()
final class PreviewSalesWorkingStatePricingQuery
    extends QueryBase<SalesWorkingStatePricingPreviewDto>
    implements
        IQuery<SalesWorkingStatePricingPreviewDto>,
        ITenantScopedCommand {
  PreviewSalesWorkingStatePricingQuery({
    String? id,
    this.tenantId = '',
    required this.storeId,
    required String currencyCode,
    required this.contextVersion,
    required DateTime effectiveAt,
    required this.lines,
    this.customerId,
  }) : currencyCode = currencyCode.trim().toUpperCase(),
       effectiveAt = effectiveAt.toUtc(),
       super(id);

  @override
  final String tenantId;
  final String storeId;
  final String? customerId;
  final String currencyCode;
  final int contextVersion;
  final DateTime effectiveAt;
  final List<SalesPricingLineInput> lines;

  PreviewSalesWorkingStatePricingQuery withExecutionContext({
    required String tenantId,
  }) => PreviewSalesWorkingStatePricingQuery(
    id: id,
    tenantId: tenantId,
    storeId: storeId,
    customerId: customerId,
    currencyCode: currencyCode,
    contextVersion: contextVersion,
    effectiveAt: effectiveAt,
    lines: lines,
  );
}
