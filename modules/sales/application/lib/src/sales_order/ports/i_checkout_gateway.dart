import '../../shared/checkout_precheck_dto.dart';
import '../../shared/checkout_result_dto.dart';
import '../commands/finalize_sales_order/finalize_sales_order_command.dart';
import '../queries/get_checkout_result/get_checkout_result_query.dart';
import '../queries/precheck_sales_order_checkout/precheck_sales_order_checkout_query.dart';

abstract interface class ICheckoutGateway {
  Future<CheckoutPrecheckDto> precheck(PrecheckSalesOrderCheckoutQuery query);

  Future<CheckoutResultDto> finalize(FinalizeSalesOrderCommand command);

  Future<CheckoutResultDto> getResult(GetCheckoutResultQuery query);
}
