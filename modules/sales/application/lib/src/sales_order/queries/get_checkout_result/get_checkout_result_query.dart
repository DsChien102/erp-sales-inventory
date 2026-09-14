import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_contract_base.dart';
import '../../../shared/checkout_result_dto.dart';

@RequiresPermission(SalesPermissions.viewOrder)
@RequiresTenant()
final class GetCheckoutResultQuery extends SalesReadContract<CheckoutResultDto> {
  GetCheckoutResultQuery({
    super.id,
    super.tenantId,
    super.actorId,
    required this.idempotencyKey,
    required this.storeId,
  });

  final String idempotencyKey;
  final String storeId;

  GetCheckoutResultQuery withExecutionContext({
    required String tenantId,
    String actorId = '',
  }) => GetCheckoutResultQuery(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    idempotencyKey: idempotencyKey,
    storeId: storeId,
  );
}
