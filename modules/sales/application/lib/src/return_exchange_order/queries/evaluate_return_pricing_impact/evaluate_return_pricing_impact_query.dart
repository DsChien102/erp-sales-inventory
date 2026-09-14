import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_contract_base.dart';
import '../../../shared/return_exchange_valuation_dto.dart';

@RequiresPermission(SalesPermissions.viewReturnExchange)
@RequiresTenant()
final class EvaluateReturnPricingImpactQuery extends SalesReadContract<ReturnExchangeValuationDto> {
  EvaluateReturnPricingImpactQuery({
    super.id,
    super.tenantId,
    super.actorId,
    required this.returnExchangeId,
    this.expectedSourceVersion,
  });

  final String returnExchangeId;
  final int? expectedSourceVersion;

  EvaluateReturnPricingImpactQuery withExecutionContext({
    required String tenantId,
    String actorId = '',
  }) => EvaluateReturnPricingImpactQuery(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    returnExchangeId: returnExchangeId,
    expectedSourceVersion: expectedSourceVersion,
  );
}
