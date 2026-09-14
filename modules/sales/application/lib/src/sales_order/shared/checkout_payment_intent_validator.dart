import '../../shared/money_dto.dart';
import '../../shared/payment_intent_input.dart';
import '../../shared/sales_blocker_dto.dart';
import 'checkout_blocker_codes.dart';

final class CheckoutPaymentIntentDecision {
  CheckoutPaymentIntentDecision({
    required this.totalPaymentIntent,
    required this.remainingAmount,
    required this.previewStatus,
    required List<SalesBlockerDto> blockers,
  }) : blockers = List.unmodifiable(blockers);

  final MoneyDto totalPaymentIntent;
  final MoneyDto remainingAmount;
  final String previewStatus;
  final List<SalesBlockerDto> blockers;
}

final class CheckoutPaymentIntentValidator {
  CheckoutPaymentIntentDecision validate({
    required String currencyCode,
    required MoneyDto amountDue,
    required List<PaymentIntentInput> paymentIntents,
  }) {
    final blockers = <SalesBlockerDto>[];
    var totalMinor = 0;

    for (var i = 0; i < paymentIntents.length; i += 1) {
      final intent = paymentIntents[i];
      final field = 'paymentIntents[$i].amount';
      if (intent.amount.amountMinor <= 0) {
        blockers.add(
          SalesBlockerDto(
            code: CheckoutBlockerCodes.paymentIntentAmountInvalid,
            message: 'Payment intent amount must be greater than zero.',
            field: field,
          ),
        );
      }
      if (intent.amount.currencyCode != currencyCode) {
        blockers.add(
          SalesBlockerDto(
            code: CheckoutBlockerCodes.paymentIntentCurrencyMismatch,
            message: 'Payment intent currency does not match checkout currency.',
            field: field,
          ),
        );
      }
      totalMinor += intent.amount.amountMinor;
    }

    if (totalMinor > amountDue.amountMinor) {
      blockers.add(
        const SalesBlockerDto(
          code: CheckoutBlockerCodes.paymentIntentExceedsAmountDue,
          message: 'Total payment intent exceeds amount due.',
          field: 'paymentIntents',
        ),
      );
    }

    final remainingMinor = amountDue.amountMinor - totalMinor;
    final clampedRemaining = remainingMinor < 0 ? 0 : remainingMinor;
    return CheckoutPaymentIntentDecision(
      totalPaymentIntent: MoneyDto(
        amountMinor: totalMinor,
        currencyCode: currencyCode,
      ),
      remainingAmount: MoneyDto(
        amountMinor: clampedRemaining,
        currencyCode: currencyCode,
      ),
      previewStatus: _previewStatus(
        amountDueMinor: amountDue.amountMinor,
        totalPaymentIntentMinor: totalMinor,
      ),
      blockers: blockers,
    );
  }

  String _previewStatus({
    required int amountDueMinor,
    required int totalPaymentIntentMinor,
  }) {
    if (amountDueMinor <= 0 || totalPaymentIntentMinor >= amountDueMinor) {
      return 'paid';
    }
    if (totalPaymentIntentMinor == 0) {
      return 'unpaid';
    }
    return 'partially_paid';
  }
}
