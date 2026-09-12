import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/cancellation_reason_policy_dto.dart';
import '../../ports/i_sales_order_cancellation_gateway.dart';
import 'list_sales_order_cancellation_reasons_query.dart';

@QueryHandlerFor(ListSalesOrderCancellationReasonsQuery)
final class ListSalesOrderCancellationReasonsQueryHandler
    implements
        IQueryHandler<ListSalesOrderCancellationReasonsQuery, List<CancellationReasonPolicyDto>> {
  ListSalesOrderCancellationReasonsQueryHandler({
    required IPermissionChecker permissionChecker,
    required ISalesOrderCancellationGateway cancellationGateway,
  }) : _permissionChecker = permissionChecker,
       _cancellationGateway = cancellationGateway;

  final IPermissionChecker _permissionChecker;
  final ISalesOrderCancellationGateway _cancellationGateway;

  @override
  Future<List<CancellationReasonPolicyDto>> handle(
    ListSalesOrderCancellationReasonsQuery query,
  ) async {
    // QueryBus does not apply the authorization pipeline; enforce explicitly.
    await _permissionChecker.require(SalesPermissions.cancelOrder);
    final policies = await _cancellationGateway.listReasons(query);
    return List<CancellationReasonPolicyDto>.unmodifiable(policies);
  }
}
