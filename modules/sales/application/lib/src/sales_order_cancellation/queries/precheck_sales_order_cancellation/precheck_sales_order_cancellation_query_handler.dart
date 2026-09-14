import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/cancellation_precheck_dto.dart';
import '../../ports/i_sales_order_cancellation_gateway.dart';
import 'precheck_sales_order_cancellation_query.dart';

@QueryHandlerFor(PrecheckSalesOrderCancellationQuery)
final class PrecheckSalesOrderCancellationQueryHandler
    implements IQueryHandler<PrecheckSalesOrderCancellationQuery, CancellationPrecheckDto> {
  PrecheckSalesOrderCancellationQueryHandler({
    required IPermissionChecker permissionChecker,
    required ISalesOrderCancellationGateway cancellationGateway,
  }) : _permissionChecker = permissionChecker,
       _cancellationGateway = cancellationGateway;

  final IPermissionChecker _permissionChecker;
  final ISalesOrderCancellationGateway _cancellationGateway;

  @override
  Future<CancellationPrecheckDto> handle(
    PrecheckSalesOrderCancellationQuery query,
  ) async {
    // QueryBus does not apply the authorization pipeline; enforce explicitly.
    await _permissionChecker.require(SalesPermissions.cancelOrder);
    return _cancellationGateway.precheck(query);
  }
}
