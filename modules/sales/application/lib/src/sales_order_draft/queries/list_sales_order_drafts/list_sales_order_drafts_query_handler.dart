import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../ports/i_sales_order_draft_gateway.dart';
import '../../../shared/paged_sales_order_draft_list_dto.dart';
import 'list_sales_order_drafts_query.dart';

@QueryHandlerFor(ListSalesOrderDraftsQuery)
final class ListSalesOrderDraftsQueryHandler
    implements IQueryHandler<ListSalesOrderDraftsQuery, PagedSalesOrderDraftListDto> {
  ListSalesOrderDraftsQueryHandler({
    required ISalesOrderDraftGateway gateway,
    required IPermissionChecker permissionChecker,
  }) : _gateway = gateway,
       _permissionChecker = permissionChecker;

  final ISalesOrderDraftGateway _gateway;
  final IPermissionChecker _permissionChecker;

  @override
  Future<PagedSalesOrderDraftListDto> handle(ListSalesOrderDraftsQuery query) async {
    // QueryBus does not apply the authorization pipeline; enforce explicitly.
    await _permissionChecker.require(SalesPermissions.restoreDraft);
    return _gateway.list(query);
  }
}
