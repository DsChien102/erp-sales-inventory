import 'money_dto.dart';
import 'sales_contract_enums.dart';

final class SalesPaymentTransactionDto {
  const SalesPaymentTransactionDto({
    required this.transactionId,
    required this.method,
    required this.amount,
    required this.status,
    required this.recordedAt,
    this.transactionType = SalesPaymentTransactionType.collection,
    this.direction = SalesPaymentDirection.inflow,
    this.relatedTransactionId,
    this.sourceContext,
    this.actorId,
    this.reasonCode,
    this.reason,
  });

  final String transactionId;
  final SalesPaymentMethod method;
  final MoneyDto amount;
  final SalesPaymentStatus status;
  final DateTime recordedAt;
  final SalesPaymentTransactionType transactionType;
  final SalesPaymentDirection direction;
  final String? relatedTransactionId;
  final String? sourceContext;
  final String? actorId;
  final String? reasonCode;
  final String? reason;

  bool get countsAsCollected =>
      status == SalesPaymentStatus.confirmed &&
      transactionType == SalesPaymentTransactionType.collection &&
      direction == SalesPaymentDirection.inflow;
}
