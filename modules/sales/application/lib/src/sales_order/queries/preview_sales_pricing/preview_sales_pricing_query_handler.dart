import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/pricing_preview_dto.dart';
import '../../ports/i_pricing_preview_port.dart';
import 'preview_sales_pricing_query.dart';

@QueryHandlerFor(PreviewSalesPricingQuery)
final class PreviewSalesPricingQueryHandler
    implements IQueryHandler<PreviewSalesPricingQuery, PricingPreviewDto> {
  PreviewSalesPricingQueryHandler({
    required IPricingPreviewPort pricing,
    required IPermissionChecker permissionChecker,
  }) : _pricing = pricing,
       _permissionChecker = permissionChecker;

  final IPricingPreviewPort _pricing;
  final IPermissionChecker _permissionChecker;

  @override
  Future<PricingPreviewDto> handle(PreviewSalesPricingQuery query) async {
    // QueryBus does not apply the authorization pipeline; enforce explicitly.
    await _permissionChecker.require(SalesPermissions.finalizeCheckout);

    return _pricing.previewWorkingState(
      tenantId: query.tenantId,
      workingState: query.workingState,
    );
  }
}
