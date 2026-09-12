import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_sales_pricing_read_gateway.dart';
import '../../shared/sales_working_state_pricing_input.dart';
import '../../shared/sales_working_state_pricing_preview_dto.dart';
import 'preview_sales_working_state_pricing_query.dart';
import 'preview_sales_working_state_pricing_query_validator.dart';

@QueryHandlerFor(PreviewSalesWorkingStatePricingQuery)
final class PreviewSalesWorkingStatePricingQueryHandler
    implements
        IQueryHandler<
          PreviewSalesWorkingStatePricingQuery,
          SalesWorkingStatePricingPreviewDto
        > {
  PreviewSalesWorkingStatePricingQueryHandler({
    required ISalesPricingReadGateway readGateway,
    required PreviewSalesWorkingStatePricingQueryValidator validator,
  }) : _readGateway = readGateway,
       _validator = validator;

  final ISalesPricingReadGateway _readGateway;
  final PreviewSalesWorkingStatePricingQueryValidator _validator;

  @override
  Future<SalesWorkingStatePricingPreviewDto> handle(
    PreviewSalesWorkingStatePricingQuery query,
  ) async {
    await _validator.validate(query);
    return _readGateway.previewWorkingState(
      SalesWorkingStatePricingInput(
        tenantId: query.tenantId,
        storeId: query.storeId,
        customerId: query.customerId,
        currencyCode: query.currencyCode,
        contextVersion: query.contextVersion,
        effectiveAt: query.effectiveAt,
        lines: query.lines,
      ),
    );
  }
}
