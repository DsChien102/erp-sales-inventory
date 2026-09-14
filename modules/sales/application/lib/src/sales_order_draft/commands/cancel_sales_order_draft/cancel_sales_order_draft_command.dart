import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_contract_base.dart';
import '../../../shared/sales_order_draft_dto.dart';

@RequiresPermission(SalesPermissions.deleteDraft)
@RequiresTenant()
final class CancelSalesOrderDraftCommand extends SalesMutationContract<SalesOrderDraftDto>
    implements ICommand<SalesOrderDraftDto>, ITenantScopedCommand {
  CancelSalesOrderDraftCommand({
    super.id,
    super.tenantId,
    super.actorId,
    required this.draftId,
    required this.storeId,
    required super.idempotencyKey,
    required int expectedVersion,
    super.payloadHash,
    super.correlationId,
    super.causationId,
  }) : super(expectedSourceVersion: expectedVersion);

  final String draftId;
  final String storeId;
  int get expectedVersion => expectedSourceVersion!;

  CancelSalesOrderDraftCommand withExecutionContext({
    required String tenantId,
    required String actorId,
  }) => CancelSalesOrderDraftCommand(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    draftId: draftId,
    storeId: storeId,
    idempotencyKey: idempotencyKey,
    expectedVersion: expectedVersion,
    payloadHash: payloadHash,
    correlationId: correlationId,
    causationId: causationId,
  );
}
