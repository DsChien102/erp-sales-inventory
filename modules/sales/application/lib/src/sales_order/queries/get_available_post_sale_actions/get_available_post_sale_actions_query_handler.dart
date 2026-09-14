import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/available_post_sale_actions_dto.dart';
import '../../ports/i_post_sale_actions_gateway.dart';
import 'get_available_post_sale_actions_query.dart';

@QueryHandlerFor(GetAvailablePostSaleActionsQuery)
final class GetAvailablePostSaleActionsQueryHandler
    implements IQueryHandler<GetAvailablePostSaleActionsQuery, AvailablePostSaleActionsDto> {
  GetAvailablePostSaleActionsQueryHandler({
    required IPermissionChecker permissionChecker,
    required IPostSaleActionsGateway postSaleActionsGateway,
  }) : _permissionChecker = permissionChecker,
       _postSaleActionsGateway = postSaleActionsGateway;

  final IPermissionChecker _permissionChecker;
  final IPostSaleActionsGateway _postSaleActionsGateway;

  @override
  Future<AvailablePostSaleActionsDto> handle(
    GetAvailablePostSaleActionsQuery query,
  ) async {
    // QueryBus does not apply the authorization pipeline; enforce explicitly.
    await _permissionChecker.require(SalesPermissions.viewOrder);
    return _postSaleActionsGateway.getAvailableActions(query);
  }
}
