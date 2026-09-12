import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../enums/sales_payment_method.dart';
import '../../enums/sales_payment_status.dart';
import '../../enums/sales_payment_transaction_kind.dart';
import '../sales_payment_transaction_id.dart';

final class SalesPaymentTransaction extends Entity<SalesPaymentTransactionId> {
  SalesPaymentTransaction({
    required super.id,
    required this.kind,
    required this.method,
    required this.amount,
    required this.status,
    this.voidsTransactionId,
  });

  final SalesPaymentTransactionKind kind;
  final SalesPaymentMethod method;
  final Money amount;
  SalesPaymentStatus status;
  final SalesPaymentTransactionId? voidsTransactionId;

  factory SalesPaymentTransaction.recordInitial({
    required SalesPaymentTransactionId id,
    required int amountMinor,
    required String currencyCode,
    required SalesPaymentMethod method,
  }) {
    return SalesPaymentTransaction(
      id: id,
      kind: SalesPaymentTransactionKind.collection,
      method: method,
      amount: Money(
        amountMinor: amountMinor,
        currencyCode: currencyCode.trim().toUpperCase(),
      ),
      status: SalesPaymentStatus.confirmed,
    );
  }
}
