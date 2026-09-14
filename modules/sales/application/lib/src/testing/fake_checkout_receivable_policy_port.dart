import '../sales_order/ports/i_checkout_receivable_policy_port.dart';
import '../sales_order/shared/checkout_blocker_codes.dart';
import '../shared/money_dto.dart';
import '../shared/sales_blocker_dto.dart';

final class FakeCheckoutReceivablePolicyPort implements ICheckoutReceivablePolicyPort {
  const FakeCheckoutReceivablePolicyPort({
    this.allowed = true,
    this.requiresDueDatePolicy = false,
    this.blockers = const <SalesBlockerDto>[],
  });

  factory FakeCheckoutReceivablePolicyPort.notEligible() {
    return const FakeCheckoutReceivablePolicyPort(
      allowed: false,
      blockers: <SalesBlockerDto>[
        SalesBlockerDto(
          code: CheckoutBlockerCodes.receivableNotAllowed,
          message: 'Customer or actor is not eligible for receivable checkout.',
          field: 'customerId',
        ),
      ],
    );
  }

  factory FakeCheckoutReceivablePolicyPort.requiresDueDate() {
    return const FakeCheckoutReceivablePolicyPort(
      allowed: false,
      requiresDueDatePolicy: true,
      blockers: <SalesBlockerDto>[
        SalesBlockerDto(
          code: CheckoutBlockerCodes.receivableDueDateRequired,
          message: 'Receivable due date is required by policy.',
          field: 'dueDate',
        ),
      ],
    );
  }

  final bool allowed;
  final bool requiresDueDatePolicy;
  final List<SalesBlockerDto> blockers;

  @override
  Future<CheckoutReceivablePolicyDecision> evaluate({
    required String storeId,
    required String customerId,
    required MoneyDto outstanding,
    DateTime? dueDate,
  }) async {
    return CheckoutReceivablePolicyDecision(
      allowed: allowed,
      requiresDueDate: requiresDueDatePolicy,
      blockers: blockers,
    );
  }
}
