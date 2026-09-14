import '../../shared/money_dto.dart';
import '../../shared/sales_blocker_dto.dart';

final class CheckoutReceivablePolicyDecision {
  CheckoutReceivablePolicyDecision({
    required this.allowed,
    required this.requiresDueDate,
    required List<SalesBlockerDto> blockers,
  }) : blockers = List.unmodifiable(blockers);

  final bool allowed;
  final bool requiresDueDate;
  final List<SalesBlockerDto> blockers;
}

abstract interface class ICheckoutReceivablePolicyPort {
  Future<CheckoutReceivablePolicyDecision> evaluate({
    required String storeId,
    required String customerId,
    required MoneyDto outstanding,
    DateTime? dueDate,
  });
}
