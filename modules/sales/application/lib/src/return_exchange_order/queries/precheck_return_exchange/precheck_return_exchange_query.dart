import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_contract_base.dart';
import '../../../shared/return_exchange_precheck_dto.dart';

@RequiresPermission(SalesPermissions.createReturnExchange)
@RequiresTenant()
final class PrecheckReturnExchangeQuery extends SalesReadContract<ReturnExchangePrecheckDto> {
  PrecheckReturnExchangeQuery({
    super.id,
    super.tenantId,
    super.actorId,
    required this.salesOrderId,
    this.expectedSourceVersion,
  });

  final String salesOrderId;
  final int? expectedSourceVersion;

  PrecheckReturnExchangeQuery withExecutionContext({
    required String tenantId,
    String actorId = '',
  }) => PrecheckReturnExchangeQuery(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    salesOrderId: salesOrderId,
    expectedSourceVersion: expectedSourceVersion,
  );
}
