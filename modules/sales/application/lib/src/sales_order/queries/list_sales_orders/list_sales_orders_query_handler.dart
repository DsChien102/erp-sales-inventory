import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/paged_sales_order_list_dto.dart';
import '../../ports/i_sales_order_inquiry_gateway.dart';
import 'list_sales_orders_query.dart';

@QueryHandlerFor(ListSalesOrdersQuery)
final class ListSalesOrdersQueryHandler
    implements IQueryHandler<ListSalesOrdersQuery, PagedSalesOrderListDto> {
  ListSalesOrdersQueryHandler({
    required IPermissionChecker permissionChecker,
    required ISalesOrderInquiryGateway inquiryGateway,
  }) : _permissionChecker = permissionChecker,
       _inquiryGateway = inquiryGateway;

  final IPermissionChecker _permissionChecker;
  final ISalesOrderInquiryGateway _inquiryGateway;

  @override
  Future<PagedSalesOrderListDto> handle(ListSalesOrdersQuery query) async {
    // QueryBus does not apply the authorization pipeline; enforce explicitly.
    await _permissionChecker.require(SalesPermissions.viewOrder);
    return _inquiryGateway.listSalesOrders(query);
  }
}
