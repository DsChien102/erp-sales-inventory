import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/return_exchange_detail_dto.dart';
import '../../../shared/sales_contract_base.dart';

@RequiresPermission(SalesPermissions.viewReturnExchange)
@RequiresTenant()
final class GetReturnExchangeDetailQuery extends SalesReadContract<ReturnExchangeDetailDto> {
  GetReturnExchangeDetailQuery({
    super.id,
    super.tenantId,
    super.actorId,
    required this.returnExchangeId,
    this.expectedVersion,
  });

  final String returnExchangeId;
  final int? expectedVersion;

  GetReturnExchangeDetailQuery withExecutionContext({
    required String tenantId,
    String actorId = '',
  }) => GetReturnExchangeDetailQuery(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    returnExchangeId: returnExchangeId,
    expectedVersion: expectedVersion,
  );
}
