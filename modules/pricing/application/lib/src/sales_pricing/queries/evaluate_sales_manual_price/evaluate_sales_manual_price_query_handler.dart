import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_sales_pricing_read_gateway.dart';
import '../../shared/sales_manual_price_evaluation_dto.dart';
import 'evaluate_sales_manual_price_query.dart';
import 'evaluate_sales_manual_price_query_validator.dart';

@QueryHandlerFor(EvaluateSalesManualPriceQuery)
final class EvaluateSalesManualPriceQueryHandler
    implements
        IQueryHandler<
          EvaluateSalesManualPriceQuery,
          SalesManualPriceEvaluationDto
        > {
  EvaluateSalesManualPriceQueryHandler({
    required ISalesPricingReadGateway readGateway,
    required EvaluateSalesManualPriceQueryValidator validator,
    required IPermissionChecker permissionChecker,
  }) : _readGateway = readGateway,
       _validator = validator,
       _permissionChecker = permissionChecker;

  final ISalesPricingReadGateway _readGateway;
  final EvaluateSalesManualPriceQueryValidator _validator;
  final IPermissionChecker _permissionChecker;

  @override
  Future<SalesManualPriceEvaluationDto> handle(
    EvaluateSalesManualPriceQuery query,
  ) async {
    await _validator.validate(query);
    final result = await _readGateway.evaluateManualPrice(query);
    if (result.requiresAcknowledgement) {
      await _permissionChecker.require(PricingPermissions.overrideFloorPrice);
    }
    return result;
  }
}
