import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/return_exchange_pricing_preview_dto.dart';
import '../../ports/i_return_exchange_read_gateway.dart';
import 'preview_return_exchange_pricing_query.dart';

@QueryHandlerFor(PreviewReturnExchangePricingQuery)
final class PreviewReturnExchangePricingQueryHandler
    implements IQueryHandler<PreviewReturnExchangePricingQuery, ReturnExchangePricingPreviewDto> {
  PreviewReturnExchangePricingQueryHandler({
    required IPermissionChecker permissionChecker,
    required IReturnExchangeReadGateway returnExchangeReadGateway,
  }) : _permissionChecker = permissionChecker,
       _returnExchangeReadGateway = returnExchangeReadGateway;

  final IPermissionChecker _permissionChecker;
  final IReturnExchangeReadGateway _returnExchangeReadGateway;

  @override
  Future<ReturnExchangePricingPreviewDto> handle(PreviewReturnExchangePricingQuery query) async {
    await _permissionChecker.require(SalesPermissions.createReturnExchange);
    return _returnExchangeReadGateway.previewPricing(query);
  }
}
