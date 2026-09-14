import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/checkout_precheck_dto.dart';
import '../../ports/i_checkout_gateway.dart';
import 'precheck_sales_order_checkout_query.dart';

@QueryHandlerFor(PrecheckSalesOrderCheckoutQuery)
final class PrecheckSalesOrderCheckoutQueryHandler
    implements IQueryHandler<PrecheckSalesOrderCheckoutQuery, CheckoutPrecheckDto> {
  PrecheckSalesOrderCheckoutQueryHandler({
    required IPermissionChecker permissionChecker,
    required ICheckoutGateway checkoutGateway,
  }) : _permissionChecker = permissionChecker,
       _checkoutGateway = checkoutGateway;

  final IPermissionChecker _permissionChecker;
  final ICheckoutGateway _checkoutGateway;

  @override
  Future<CheckoutPrecheckDto> handle(PrecheckSalesOrderCheckoutQuery query) async {
    await _permissionChecker.require(SalesPermissions.finalizeCheckout);
    return _checkoutGateway.precheck(query);
  }
}
