import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_order_detail_dto.dart';
import '../../ports/i_sales_order_inquiry_gateway.dart';
import 'get_sales_order_detail_query.dart';

@QueryHandlerFor(GetSalesOrderDetailQuery)
final class GetSalesOrderDetailQueryHandler
    implements IQueryHandler<GetSalesOrderDetailQuery, SalesOrderDetailDto> {
  GetSalesOrderDetailQueryHandler({
    required IPermissionChecker permissionChecker,
    required ISalesOrderInquiryGateway inquiryGateway,
  }) : _permissionChecker = permissionChecker,
       _inquiryGateway = inquiryGateway;

  final IPermissionChecker _permissionChecker;
  final ISalesOrderInquiryGateway _inquiryGateway;

  @override
  Future<SalesOrderDetailDto> handle(GetSalesOrderDetailQuery query) async {
    // QueryBus does not apply the authorization pipeline; enforce explicitly.
    await _permissionChecker.require(SalesPermissions.viewOrder);
    return _inquiryGateway.getSalesOrderDetail(query);
  }
}
