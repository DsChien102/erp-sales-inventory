import 'package:vet45_shared_application/application.dart';
import 'package:vet45_sales_domain/domain.dart';

import '../../../shared/checkout_result_dto.dart';
import '../../../shared/sales_contract_enums.dart';
import '../../ports/i_checkout_gateway.dart';
import '../../queries/precheck_sales_order_checkout/precheck_sales_order_checkout_query.dart';
import 'finalize_sales_order_command.dart';

@CommandHandlerFor(FinalizeSalesOrderCommand)
final class FinalizeSalesOrderCommandHandler
    implements ICommandHandler<FinalizeSalesOrderCommand, CheckoutResultDto> {
  FinalizeSalesOrderCommandHandler({
    required ICheckoutGateway checkoutGateway,
    required IPermissionChecker permissionChecker,
  }) : _checkoutGateway = checkoutGateway,
       _permissionChecker = permissionChecker;

  final ICheckoutGateway _checkoutGateway;
  final IPermissionChecker _permissionChecker;

  @override
  Future<CheckoutResultDto> handle(FinalizeSalesOrderCommand command) async {
    if (command.paymentIntents.isNotEmpty) {
      await _permissionChecker.require(SalesPermissions.recordPayment);
    }
    final precheck = await _checkoutGateway.precheck(
      PrecheckSalesOrderCheckoutQuery(
        id: command.id,
        tenantId: command.tenantId,
        actorId: command.actorId,
        storeId: command.storeId,
        customerId: command.customerId,
        currencyCode: command.currencyCode,
        paymentDueDate: command.paymentDueDate,
        lines: command.lines,
        paymentIntents: command.paymentIntents,
        expectedSourceVersion: command.expectedSourceVersion,
      ),
    );
    if (!precheck.canFinalize || precheck.blockers.isNotEmpty) {
      return CheckoutResultDto(
        idempotencyKey: command.idempotencyKey,
        salesOrderId: '',
        salesOrderVersion: 0,
        status: CheckoutResultStatus.blocked,
      );
    }
    return _checkoutGateway.finalize(command);
  }
}
