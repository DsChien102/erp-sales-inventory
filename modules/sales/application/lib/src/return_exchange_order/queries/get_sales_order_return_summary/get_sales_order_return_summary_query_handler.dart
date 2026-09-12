import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_order_return_summary_dto.dart';
import '../../../sales_order/ports/i_sales_order_inquiry_gateway.dart';
import 'get_sales_order_return_summary_query.dart';

@QueryHandlerFor(GetSalesOrderReturnSummaryQuery)
final class GetSalesOrderReturnSummaryQueryHandler
    implements IQueryHandler<GetSalesOrderReturnSummaryQuery, SalesOrderReturnSummaryDto> {
  GetSalesOrderReturnSummaryQueryHandler({
    required IPermissionChecker permissionChecker,
    required ISalesOrderInquiryGateway inquiryGateway,
  }) : _permissionChecker = permissionChecker,
       _inquiryGateway = inquiryGateway;

  final IPermissionChecker _permissionChecker;
  final ISalesOrderInquiryGateway _inquiryGateway;

  @override
  Future<SalesOrderReturnSummaryDto> handle(
    GetSalesOrderReturnSummaryQuery query,
  ) async {
    // QueryBus does not apply the authorization pipeline; enforce explicitly.
    await _permissionChecker.require(SalesPermissions.viewReturnExchange);
    return _inquiryGateway.getReturnSummary(query);
  }
}
