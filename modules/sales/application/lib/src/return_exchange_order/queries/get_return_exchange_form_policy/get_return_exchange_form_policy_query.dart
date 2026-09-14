import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/return_exchange_form_policy_dto.dart';
import '../../../shared/sales_contract_base.dart';

@RequiresPermission(SalesPermissions.createReturnExchange)
@RequiresTenant()
final class GetReturnExchangeFormPolicyQuery
    extends SalesReadContract<ReturnExchangeFormPolicyDto> {
  GetReturnExchangeFormPolicyQuery({
    super.id,
    super.tenantId,
    super.actorId,
  });

  GetReturnExchangeFormPolicyQuery withExecutionContext({
    required String tenantId,
    String actorId = '',
  }) => GetReturnExchangeFormPolicyQuery(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
  );
}
