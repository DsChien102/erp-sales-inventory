import 'money_dto.dart';

final class SalesOrderPaymentOriginalBreakdownDto {
  const SalesOrderPaymentOriginalBreakdownDto({
    required this.orderTotal,
    required this.paidCash,
    required this.paidBank,
    required this.outstanding,
  });

  final MoneyDto orderTotal;
  final MoneyDto paidCash;
  final MoneyDto paidBank;
  final MoneyDto outstanding;
}
