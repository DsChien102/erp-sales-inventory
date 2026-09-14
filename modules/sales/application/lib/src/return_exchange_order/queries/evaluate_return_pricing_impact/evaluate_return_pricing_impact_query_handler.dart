import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/return_exchange_valuation_dto.dart';
import '../../../shared/sales_contract_exception.dart';
import '../../ports/i_return_exchange_read_gateway.dart';
import '../../ports/i_return_exchange_reference_port.dart';
import 'evaluate_return_pricing_impact_query.dart';

@QueryHandlerFor(EvaluateReturnPricingImpactQuery)
final class EvaluateReturnPricingImpactQueryHandler
    implements IQueryHandler<EvaluateReturnPricingImpactQuery, ReturnExchangeValuationDto> {
  EvaluateReturnPricingImpactQueryHandler({
    required IPermissionChecker permissionChecker,
    required IReturnExchangeReadGateway readGateway,
    required IReturnExchangeReferencePort referencePort,
  }) : _permissionChecker = permissionChecker,
       _readGateway = readGateway,
       _referencePort = referencePort;

  final IPermissionChecker _permissionChecker;
  final IReturnExchangeReadGateway _readGateway;
  final IReturnExchangeReferencePort _referencePort;

  @override
  Future<ReturnExchangeValuationDto> handle(
    EvaluateReturnPricingImpactQuery query,
  ) async {
    // QueryBus does not apply the authorization pipeline; enforce explicitly.
    await _permissionChecker.require(SalesPermissions.viewReturnExchange);

    final context = await _readGateway.getContext(
      tenantId: query.tenantId,
      actorId: query.actorId,
      returnExchangeId: query.returnExchangeId,
    );

    final decision = await _referencePort.evaluate(
      tenantId: query.tenantId,
      actorId: query.actorId,
      salesOrderId: context.draft.salesOrderId,
      lines: context.draft.lines,
      reserveExchangeStock: false,
    );
    if (!decision.allowed) {
      throw SalesContractException(
        'RETURN_EXCHANGE_BLOCKED',
        details: <String, Object?>{'blockers': decision.blockers},
      );
    }

    return _readGateway.evaluate(
      query,
      referenceDecision: decision,
    );
  }
}
