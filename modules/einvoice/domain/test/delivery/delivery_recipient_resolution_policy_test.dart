import 'package:test/test.dart';
import 'package:vet45_einvoice_domain/domain.dart';

void main() {
  group('DeliveryRecipientResolutionPolicy', () {
    group('automatic initial', () {
      test('prefers current Partner invoice email', () {
        final result = DeliveryRecipientResolutionPolicy.resolveAutomaticInitial(
          currentPartnerInvoiceEmail: 'partner@clinic.vn',
          buyerInvoiceSnapshotEmail: 'snapshot@clinic.vn',
          buyerPartnerId: 'partner-1',
        );

        expect(result.isResolved, isTrue);
        expect(result.email, 'partner@clinic.vn');
        expect(result.source, DeliveryRecipientSource.currentPartnerProfile);
      });

      test('falls back to immutable BuyerInvoiceSnapshot email', () {
        final result = DeliveryRecipientResolutionPolicy.resolveAutomaticInitial(
          currentPartnerInvoiceEmail: null,
          buyerInvoiceSnapshotEmail: 'snapshot@clinic.vn',
          buyerPartnerId: 'partner-1',
        );

        expect(result.isResolved, isTrue);
        expect(result.email, 'snapshot@clinic.vn');
        expect(result.source, DeliveryRecipientSource.buyerInvoiceSnapshot);
      });

      test('skips safely when both candidates are absent', () {
        final result = DeliveryRecipientResolutionPolicy.resolveAutomaticInitial(
          currentPartnerInvoiceEmail: null,
          buyerInvoiceSnapshotEmail: null,
          buyerPartnerId: 'partner-1',
        );

        expect(result.isSkip, isTrue);
        expect(result.skipReason, 'INVALID_OR_MISSING_EMAIL');
      });

      test('without stable Partner id only uses BuyerInvoiceSnapshot', () {
        final withSnapshot = DeliveryRecipientResolutionPolicy.resolveAutomaticInitial(
          currentPartnerInvoiceEmail: 'partner@clinic.vn',
          buyerInvoiceSnapshotEmail: 'snapshot@clinic.vn',
          buyerPartnerId: null,
        );
        expect(withSnapshot.email, 'snapshot@clinic.vn');
        expect(
          withSnapshot.source,
          DeliveryRecipientSource.buyerInvoiceSnapshot,
        );

        final withoutSnapshot = DeliveryRecipientResolutionPolicy.resolveAutomaticInitial(
          currentPartnerInvoiceEmail: 'partner@clinic.vn',
          buyerInvoiceSnapshotEmail: null,
          buyerPartnerId: null,
        );
        expect(withoutSnapshot.isSkip, isTrue);
      });
    });

    group('manual initial suggestion', () {
      test('prefers current Partner invoice email', () {
        final result = DeliveryRecipientResolutionPolicy.resolveManualInitialSuggestion(
          currentPartnerInvoiceEmail: 'partner@clinic.vn',
          lastSuccessfulPartnerDeliveryEmail: 'history@clinic.vn',
          buyerPartnerId: 'partner-1',
          lastSuccessfulDeliveryBuyerPartnerId: 'partner-1',
        );

        expect(result.isResolved, isTrue);
        expect(result.email, 'partner@clinic.vn');
        expect(result.source, DeliveryRecipientSource.currentPartnerProfile);
      });

      test('falls back to latest successful same-Partner delivery', () {
        final result = DeliveryRecipientResolutionPolicy.resolveManualInitialSuggestion(
          currentPartnerInvoiceEmail: null,
          lastSuccessfulPartnerDeliveryEmail: 'history@clinic.vn',
          buyerPartnerId: 'partner-1',
          lastSuccessfulDeliveryBuyerPartnerId: 'partner-1',
        );

        expect(result.email, 'history@clinic.vn');
        expect(
          result.source,
          DeliveryRecipientSource.lastSuccessfulPartnerDelivery,
        );
      });

      test('returns blank when all candidates are absent', () {
        final result = DeliveryRecipientResolutionPolicy.resolveManualInitialSuggestion(
          currentPartnerInvoiceEmail: null,
          lastSuccessfulPartnerDeliveryEmail: null,
          buyerPartnerId: 'partner-1',
          lastSuccessfulDeliveryBuyerPartnerId: 'partner-1',
        );

        expect(result.isBlank, isTrue);
      });

      test('rejects Partner mismatch and never uses cross-customer history', () {
        final result = DeliveryRecipientResolutionPolicy.resolveManualInitialSuggestion(
          currentPartnerInvoiceEmail: null,
          lastSuccessfulPartnerDeliveryEmail: 'other-customer@clinic.vn',
          buyerPartnerId: 'partner-1',
          lastSuccessfulDeliveryBuyerPartnerId: 'partner-other',
        );

        expect(result.isBlank, isTrue);
      });

      test('disables history fallback without stable Partner id', () {
        final result = DeliveryRecipientResolutionPolicy.resolveManualInitialSuggestion(
          currentPartnerInvoiceEmail: null,
          lastSuccessfulPartnerDeliveryEmail: 'history@clinic.vn',
          buyerPartnerId: null,
          lastSuccessfulDeliveryBuyerPartnerId: 'partner-1',
        );

        expect(result.isBlank, isTrue);
      });
    });

    group('manual resend suggestion', () {
      test('uses latest delivery recipient for the same invoice', () {
        final result = DeliveryRecipientResolutionPolicy.resolveManualResendSuggestion(
          latestInvoiceDeliveryEmail: 'last@clinic.vn',
        );

        expect(result.email, 'last@clinic.vn');
        expect(result.source, DeliveryRecipientSource.lastInvoiceDelivery);
      });

      test('returns blank when no prior delivery recipient exists', () {
        final result = DeliveryRecipientResolutionPolicy.resolveManualResendSuggestion(
          latestInvoiceDeliveryEmail: null,
        );

        expect(result.isBlank, isTrue);
      });
    });

    group('manual confirmed send', () {
      test('persists validated user input as USER_INPUT', () {
        final result = DeliveryRecipientResolutionPolicy.resolveManualConfirmed(
          userEmail: 'typed@clinic.vn',
        );

        expect(result.email, 'typed@clinic.vn');
        expect(result.source, DeliveryRecipientSource.userInput);
      });
    });
  });
}
