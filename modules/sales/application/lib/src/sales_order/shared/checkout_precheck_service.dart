import '../../shared/checkout_line_input.dart';
import '../../shared/checkout_monetary_summary_dto.dart';
import '../../shared/checkout_precheck_dto.dart';
import '../../shared/money_dto.dart';
import '../../shared/receivable_requirement_dto.dart';
import '../../shared/sales_blocker_dto.dart';
import '../ports/i_checkout_reference_precheck_port.dart';
import '../ports/i_checkout_receivable_policy_port.dart';
import '../queries/precheck_sales_order_checkout/precheck_sales_order_checkout_query.dart';
import 'checkout_blocker_codes.dart';
import 'checkout_payment_intent_validator.dart';

final class CheckoutPrecheckService {
  CheckoutPrecheckService({
    ICheckoutReferencePrecheckPort? referencePrecheck,
    ICheckoutReceivablePolicyPort? receivablePolicy,
    CheckoutPaymentIntentValidator? paymentIntentValidator,
  }) : _referencePrecheck = referencePrecheck ?? const _DefaultCheckoutReferencePrecheckPort(),
       _receivablePolicy = receivablePolicy ?? const _DefaultCheckoutReceivablePolicyPort(),
       _paymentIntentValidator = paymentIntentValidator ?? CheckoutPaymentIntentValidator();

  final ICheckoutReferencePrecheckPort _referencePrecheck;
  final ICheckoutReceivablePolicyPort _receivablePolicy;
  final CheckoutPaymentIntentValidator _paymentIntentValidator;

  Future<CheckoutPrecheckDto> precheck(
    PrecheckSalesOrderCheckoutQuery query,
  ) async {
    final structural = _structuralBlockers(query);
    final reference = await _referencePrecheck.precheck(
      storeId: query.storeId,
      customerId: query.customerId,
      currencyCode: query.currencyCode,
      lines: query.lines,
      expectedSourceVersion: query.expectedSourceVersion,
    );
    final payment = _paymentIntentValidator.validate(
      currencyCode: query.currencyCode,
      amountDue: reference.pricingSummary.grandTotal,
      paymentIntents: query.paymentIntents,
    );
    final receivable = await _receivableRequirement(
      query: query,
      outstanding: payment.remainingAmount,
    );
    final blockers = <SalesBlockerDto>[
      ...structural,
      ...reference.blockers,
      ...payment.blockers,
      ...receivable.blockers,
    ];
    return CheckoutPrecheckDto(
      canFinalize: blockers.isEmpty,
      blockers: blockers,
      monetarySummary: reference.pricingSummary,
      receivableRequirement: receivable.requirement,
    );
  }

  Future<_ReceivablePrecheckResult> _receivableRequirement({
    required PrecheckSalesOrderCheckoutQuery query,
    required MoneyDto outstanding,
  }) async {
    final isRequired = outstanding.amountMinor > 0;
    final requirement = ReceivableRequirementDto(
      isRequired: isRequired,
      amount: outstanding,
      customerId: query.customerId,
    );
    if (!isRequired) {
      return _ReceivablePrecheckResult(
        requirement: requirement,
        blockers: const <SalesBlockerDto>[],
      );
    }
    final customerId = query.customerId;
    if (customerId == null || customerId.trim().isEmpty) {
      return _ReceivablePrecheckResult(
        requirement: requirement,
        blockers: const <SalesBlockerDto>[
          SalesBlockerDto(
            code: CheckoutBlockerCodes.walkInReceivableBlocked,
            message: 'Walk-in customer cannot create receivable.',
            field: 'customerId',
          ),
        ],
      );
    }
    final policy = await _receivablePolicy.evaluate(
      storeId: query.storeId,
      customerId: customerId,
      outstanding: outstanding,
      dueDate: query.paymentDueDate,
    );
    return _ReceivablePrecheckResult(
      requirement: requirement,
      blockers: policy.blockers,
    );
  }

  List<SalesBlockerDto> _structuralBlockers(
    PrecheckSalesOrderCheckoutQuery query,
  ) {
    final blockers = <SalesBlockerDto>[];
    if (query.lines.isEmpty) {
      blockers.add(
        const SalesBlockerDto(
          code: CheckoutBlockerCodes.contextInvalid,
          message: 'Checkout requires at least one line.',
          field: 'lines',
        ),
      );
    }
    for (var i = 0; i < query.lines.length; i += 1) {
      final line = query.lines[i];
      final field = 'lines[$i]';
      if (line.quantity.quantityMicros <= 0) {
        blockers.add(
          SalesBlockerDto(
            code: CheckoutBlockerCodes.contextInvalid,
            message: 'Quantity must be greater than zero.',
            field: field,
          ),
        );
      }
      final unitPrice = line.unitPrice;
      if (unitPrice == null) {
        blockers.add(
          SalesBlockerDto(
            code: CheckoutBlockerCodes.pricingStale,
            message: 'Pricing preview must be refreshed before checkout.',
            field: field,
          ),
        );
      } else if (unitPrice.currencyCode != query.currencyCode) {
        blockers.add(
          SalesBlockerDto(
            code: CheckoutBlockerCodes.contextInvalid,
            message: 'Line currency does not match order currency.',
            field: field,
          ),
        );
      }
    }
    return blockers;
  }
}

final class _ReceivablePrecheckResult {
  const _ReceivablePrecheckResult({
    required this.requirement,
    required this.blockers,
  });

  final ReceivableRequirementDto requirement;
  final List<SalesBlockerDto> blockers;
}

final class _DefaultCheckoutReceivablePolicyPort implements ICheckoutReceivablePolicyPort {
  const _DefaultCheckoutReceivablePolicyPort();

  @override
  Future<CheckoutReceivablePolicyDecision> evaluate({
    required String storeId,
    required String customerId,
    required MoneyDto outstanding,
    DateTime? dueDate,
  }) async {
    return CheckoutReceivablePolicyDecision(
      allowed: true,
      requiresDueDate: false,
      blockers: const <SalesBlockerDto>[],
    );
  }
}

/// Fail-closed default: no live reference-precheck provider is wired into the
/// query/command handlers yet (live RPC is deferred to S12/providers). Blocking
/// with [CheckoutBlockerCodes.dependencyUnavailable] prevents production from
/// silently allowing checkout on a fabricated "ready" summary.
final class _DefaultCheckoutReferencePrecheckPort implements ICheckoutReferencePrecheckPort {
  const _DefaultCheckoutReferencePrecheckPort();

  @override
  Future<CheckoutReferencePrecheckDecision> precheck({
    required String storeId,
    String? customerId,
    required String currencyCode,
    required List<CheckoutLineInput> lines,
    int? expectedSourceVersion,
  }) async {
    final zero = MoneyDto(amountMinor: 0, currencyCode: currencyCode);
    return CheckoutReferencePrecheckDecision(
      lines: lines,
      pricingSummary: CheckoutMonetarySummaryDto(
        subtotal: zero,
        discountTotal: zero,
        grandTotal: zero,
      ),
      blockers: const <SalesBlockerDto>[
        SalesBlockerDto(
          code: CheckoutBlockerCodes.dependencyUnavailable,
          message: 'Checkout reference precheck provider is not wired.',
          field: null,
        ),
      ],
    );
  }
}
