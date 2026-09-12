import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_order_payment_summary_dto.dart';
import '../../../sales_order/ports/i_sales_order_read_gateway.dart';
import 'get_sales_order_payment_summary_query.dart';

@QueryHandlerFor(GetSalesOrderPaymentSummaryQuery)
final class GetSalesOrderPaymentSummaryQueryHandler
    implements IQueryHandler<GetSalesOrderPaymentSummaryQuery, SalesOrderPaymentSummaryDto> {
  GetSalesOrderPaymentSummaryQueryHandler({
    required IPermissionChecker permissionChecker,
    required ISalesOrderReadGateway readGateway,
  }) : _permissionChecker = permissionChecker,
       _readGateway = readGateway;

  final IPermissionChecker _permissionChecker;
  final ISalesOrderReadGateway _readGateway;

  @override
  Future<SalesOrderPaymentSummaryDto> handle(
    GetSalesOrderPaymentSummaryQuery query,
  ) async {
    // QueryBus does not apply the authorization pipeline; enforce explicitly.
    await _permissionChecker.require(SalesPermissions.viewPayment);
    return _readGateway.getPaymentSummary(query);
  }
}
