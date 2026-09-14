import 'money_dto.dart';

final class SalesOrderPaymentReturnSlipBreakdownDto {
  const SalesOrderPaymentReturnSlipBreakdownDto({
    required this.slipNumber,
    required this.customerPaysExtra,
    this.paidCashExtra,
    this.paidBankExtra,
  });

  final String slipNumber;
  final MoneyDto customerPaysExtra;
  final MoneyDto? paidCashExtra;
  final MoneyDto? paidBankExtra;
}
