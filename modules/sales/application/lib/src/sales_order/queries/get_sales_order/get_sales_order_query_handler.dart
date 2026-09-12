import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_order_result_dto.dart';
import '../../ports/i_sales_order_read_gateway.dart';
import 'get_sales_order_query.dart';

@QueryHandlerFor(GetSalesOrderQuery)
final class GetSalesOrderQueryHandler
    implements IQueryHandler<GetSalesOrderQuery, SalesOrderResultDto> {
  GetSalesOrderQueryHandler({
    required IPermissionChecker permissionChecker,
    required ISalesOrderReadGateway readGateway,
  }) : _permissionChecker = permissionChecker,
       _readGateway = readGateway;

  final IPermissionChecker _permissionChecker;
  final ISalesOrderReadGateway _readGateway;

  @override
  Future<SalesOrderResultDto> handle(GetSalesOrderQuery query) async {
    // QueryBus does not apply the authorization pipeline; enforce explicitly.
    await _permissionChecker.require(SalesPermissions.viewOrder);
    return _readGateway.getSalesOrder(query);
  }
}
