import 'package:equatable/equatable.dart';
import 'package:erp/features/sales/data/models.dart';

/// Typed handoff from Group D checkout finalize to SG-06 result load.
///
/// Carries authoritative checkout identities only — SG-06 must not treat any
/// field here as display source for order, customer, payment, or receipt data.
final class SalesCheckoutResultArgs extends Equatable {
  const SalesCheckoutResultArgs({required this.result, required this.storeId});

  final String storeId;

  final CheckoutResultDto result;

  String get idempotencyKey => result.idempotencyKey;
  String get salesOrderId => result.salesOrderId;

  @override
  List<Object?> get props => [
    storeId,
    result.idempotencyKey,
    result.salesOrderId,
    result.salesOrderVersion,
    result.status,
  ];
}
