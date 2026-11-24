import 'money_dto.dart';

final class CheckoutMonetarySummaryDto {
  const CheckoutMonetarySummaryDto({
    required this.subtotal,
    required this.discountTotal,
    required this.grandTotal,
  });

  final MoneyDto subtotal;
  final MoneyDto discountTotal;
  final MoneyDto grandTotal;
}
