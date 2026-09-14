import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/paged_sales_order_draft_list_dto.dart';
import '../../../shared/sales_contract_base.dart';

@RequiresPermission(SalesPermissions.restoreDraft)
@RequiresTenant()
final class ListSalesOrderDraftsQuery extends SalesReadContract<PagedSalesOrderDraftListDto>
    implements IQuery<PagedSalesOrderDraftListDto>, ITenantScopedCommand {
  ListSalesOrderDraftsQuery({
    super.id,
    super.tenantId,
    super.actorId,
    required this.storeId,
    this.cursor,
    this.pageSize = 25,
  });

  final String storeId;
  final String? cursor;
  final int pageSize;

  ListSalesOrderDraftsQuery withExecutionContext({
    required String tenantId,
    String actorId = '',
  }) => ListSalesOrderDraftsQuery(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    storeId: storeId,
    cursor: cursor,
    pageSize: pageSize,
  );
}
