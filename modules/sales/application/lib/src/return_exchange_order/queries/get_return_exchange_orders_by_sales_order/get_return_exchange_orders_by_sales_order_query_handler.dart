import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../sales_order/ports/i_sales_order_inquiry_gateway.dart';
import '../../../shared/sales_order_return_summary_dto.dart';
import '../get_sales_order_return_summary/get_sales_order_return_summary_query.dart';
import 'get_return_exchange_orders_by_sales_order_query.dart';

@QueryHandlerFor(GetReturnExchangeOrdersBySalesOrderQuery)
final class GetReturnExchangeOrdersBySalesOrderQueryHandler
    implements IQueryHandler<GetReturnExchangeOrdersBySalesOrderQuery, SalesOrderReturnSummaryDto> {
  GetReturnExchangeOrdersBySalesOrderQueryHandler({
    required IPermissionChecker permissionChecker,
    required ISalesOrderInquiryGateway inquiryGateway,
  }) : _permissionChecker = permissionChecker,
       _inquiryGateway = inquiryGateway;

  final IPermissionChecker _permissionChecker;
  final ISalesOrderInquiryGateway _inquiryGateway;

  @override
  Future<SalesOrderReturnSummaryDto> handle(
    GetReturnExchangeOrdersBySalesOrderQuery query,
  ) async {
    // QueryBus does not apply the authorization pipeline; enforce explicitly.
    await _permissionChecker.require(SalesPermissions.viewReturnExchange);
    final summaryQuery = GetSalesOrderReturnSummaryQuery(
      id: query.id,
      tenantId: query.tenantId,
      actorId: query.actorId,
      salesOrderId: query.salesOrderId,
      expectedSourceVersion: query.expectedSourceVersion,
    );
    return _inquiryGateway.getReturnSummary(summaryQuery);
  }
}
