import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_order_timeline_dto.dart';
import '../../ports/i_sales_order_inquiry_gateway.dart';
import 'get_sales_order_timeline_query.dart';

@QueryHandlerFor(GetSalesOrderTimelineQuery)
final class GetSalesOrderTimelineQueryHandler
    implements IQueryHandler<GetSalesOrderTimelineQuery, SalesOrderTimelineDto> {
  GetSalesOrderTimelineQueryHandler({
    required IPermissionChecker permissionChecker,
    required ISalesOrderInquiryGateway inquiryGateway,
  }) : _permissionChecker = permissionChecker,
       _inquiryGateway = inquiryGateway;

  final IPermissionChecker _permissionChecker;
  final ISalesOrderInquiryGateway _inquiryGateway;

  @override
  Future<SalesOrderTimelineDto> handle(GetSalesOrderTimelineQuery query) async {
    // QueryBus does not apply the authorization pipeline; enforce explicitly.
    await _permissionChecker.require(SalesPermissions.viewOrderHistory);
    return _inquiryGateway.getTimeline(query);
  }
}
