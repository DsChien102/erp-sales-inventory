import 'checkout_result_dto.dart';
import 'sales_order_payment_summary_dto.dart';
import 'sales_order_result_dto.dart';

final class CheckoutResultViewDto {
  const CheckoutResultViewDto({
    required this.checkout,
    required this.order,
    required this.payment,
  });

  final CheckoutResultDto checkout;
  final SalesOrderResultDto order;
  final SalesOrderPaymentSummaryDto payment;
}
