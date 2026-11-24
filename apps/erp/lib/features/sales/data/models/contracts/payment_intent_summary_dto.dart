import 'money_dto.dart';
import 'sales_contract_enums.dart';

final class PaymentIntentSummaryDto {
  const PaymentIntentSummaryDto({
    required this.method,
    required this.amount,
    required this.status,
  });

  final SalesPaymentMethod method;
  final MoneyDto amount;
  final SalesPaymentStatus status;
}
