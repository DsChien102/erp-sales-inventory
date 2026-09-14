import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_order_settlement_dto.dart';
import '../../../sales_order/ports/i_sales_order_inquiry_gateway.dart';
import 'get_sales_order_settlement_query.dart';

@QueryHandlerFor(GetSalesOrderSettlementQuery)
final class GetSalesOrderSettlementQueryHandler
    implements IQueryHandler<GetSalesOrderSettlementQuery, SalesOrderSettlementDto> {
  GetSalesOrderSettlementQueryHandler({
    required IPermissionChecker permissionChecker,
    required ISalesOrderInquiryGateway inquiryGateway,
  }) : _permissionChecker = permissionChecker,
       _inquiryGateway = inquiryGateway;

  final IPermissionChecker _permissionChecker;
  final ISalesOrderInquiryGateway _inquiryGateway;

  @override
  Future<SalesOrderSettlementDto> handle(GetSalesOrderSettlementQuery query) async {
    // QueryBus does not apply the authorization pipeline; enforce explicitly.
    await _permissionChecker.require(SalesPermissions.viewPayment);
    return _inquiryGateway.getSettlement(query);
  }
}
