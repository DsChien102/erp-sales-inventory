import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_order_cancellation_detail_dto.dart';
import '../../ports/i_sales_order_cancellation_gateway.dart';
import 'get_sales_order_cancellation_query.dart';

@QueryHandlerFor(GetSalesOrderCancellationQuery)
final class GetSalesOrderCancellationQueryHandler
    implements IQueryHandler<GetSalesOrderCancellationQuery, SalesOrderCancellationDetailDto> {
  GetSalesOrderCancellationQueryHandler({
    required IPermissionChecker permissionChecker,
    required ISalesOrderCancellationGateway cancellationGateway,
  }) : _permissionChecker = permissionChecker,
       _cancellationGateway = cancellationGateway;

  final IPermissionChecker _permissionChecker;
  final ISalesOrderCancellationGateway _cancellationGateway;

  @override
  Future<SalesOrderCancellationDetailDto> handle(
    GetSalesOrderCancellationQuery query,
  ) async {
    // QueryBus does not apply the authorization pipeline; enforce explicitly.
    await _permissionChecker.require(SalesPermissions.viewOrder);
    return _cancellationGateway.getDetail(query);
  }
}
