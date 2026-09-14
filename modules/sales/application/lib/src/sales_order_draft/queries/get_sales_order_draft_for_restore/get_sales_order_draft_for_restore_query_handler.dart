import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../ports/i_sales_order_draft_gateway.dart';
import '../../../shared/sales_order_draft_for_restore_dto.dart';
import 'get_sales_order_draft_for_restore_query.dart';

@QueryHandlerFor(GetSalesOrderDraftForRestoreQuery)
final class GetSalesOrderDraftForRestoreQueryHandler
    implements IQueryHandler<GetSalesOrderDraftForRestoreQuery, SalesOrderDraftForRestoreDto> {
  GetSalesOrderDraftForRestoreQueryHandler({
    required ISalesOrderDraftGateway gateway,
    required IPermissionChecker permissionChecker,
  }) : _gateway = gateway,
       _permissionChecker = permissionChecker;

  final ISalesOrderDraftGateway _gateway;
  final IPermissionChecker _permissionChecker;

  @override
  Future<SalesOrderDraftForRestoreDto> handle(
    GetSalesOrderDraftForRestoreQuery query,
  ) async {
    // QueryBus does not apply the authorization pipeline; enforce explicitly.
    await _permissionChecker.require(SalesPermissions.restoreDraft);
    return _gateway.getForRestore(query);
  }
}
