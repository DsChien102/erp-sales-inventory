import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_contract_base.dart';
import '../../../shared/sales_order_draft_for_restore_dto.dart';

@RequiresPermission(SalesPermissions.restoreDraft)
@RequiresTenant()
final class GetSalesOrderDraftForRestoreQuery
    extends SalesReadContract<SalesOrderDraftForRestoreDto>
    implements IQuery<SalesOrderDraftForRestoreDto>, ITenantScopedCommand {
  GetSalesOrderDraftForRestoreQuery({
    super.id,
    super.tenantId,
    super.actorId,
    required this.draftId,
    required this.storeId,
    this.expectedSourceVersion,
  });

  final String draftId;
  final String storeId;
  final int? expectedSourceVersion;

  GetSalesOrderDraftForRestoreQuery withExecutionContext({
    required String tenantId,
    String actorId = '',
  }) => GetSalesOrderDraftForRestoreQuery(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    draftId: draftId,
    storeId: storeId,
    expectedSourceVersion: expectedSourceVersion,
  );
}
