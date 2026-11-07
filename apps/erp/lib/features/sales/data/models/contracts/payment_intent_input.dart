import 'money_dto.dart';
import 'sales_contract_enums.dart';

final class PaymentIntentInput {
  const PaymentIntentInput({
    required this.method,
    required this.amount,
    this.reference,
  });

  final SalesPaymentMethod method;
  final MoneyDto amount;
  final String? reference;
}
