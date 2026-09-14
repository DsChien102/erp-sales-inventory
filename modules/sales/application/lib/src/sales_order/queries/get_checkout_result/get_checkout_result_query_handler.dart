import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/checkout_result_dto.dart';
import '../../ports/i_checkout_gateway.dart';
import 'get_checkout_result_query.dart';

@QueryHandlerFor(GetCheckoutResultQuery)
final class GetCheckoutResultQueryHandler
    implements IQueryHandler<GetCheckoutResultQuery, CheckoutResultDto> {
  GetCheckoutResultQueryHandler({
    required IPermissionChecker permissionChecker,
    required ICheckoutGateway checkoutGateway,
  }) : _permissionChecker = permissionChecker,
       _checkoutGateway = checkoutGateway;

  final IPermissionChecker _permissionChecker;
  final ICheckoutGateway _checkoutGateway;

  @override
  Future<CheckoutResultDto> handle(GetCheckoutResultQuery query) async {
    // QueryBus does not apply the authorization pipeline; enforce explicitly.
    await _permissionChecker.require(SalesPermissions.viewOrder);
    return _checkoutGateway.getResult(query);
  }
}
