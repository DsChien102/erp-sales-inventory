import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_presentation/presentation.dart';

void main() {
  group('EInvoiceStatusInteraction', () {
    test('processing badge status never allows tap', () {
      expect(
        EInvoiceStatusInteraction.allowsTap(VBadgeStatus.processing),
        isFalse,
      );
    });

    test('non-processing badge statuses allow tap', () {
      expect(EInvoiceStatusInteraction.allowsTap(VBadgeStatus.draft), isTrue);
      expect(EInvoiceStatusInteraction.allowsTap(VBadgeStatus.success), isTrue);
      expect(EInvoiceStatusInteraction.allowsTap(VBadgeStatus.danger), isTrue);
    });

    test('issuance processing maps to non-interactive', () {
      expect(
        EInvoiceStatusInteraction.allowsTapForIssuance(
          IssuanceDisplayState.processing,
        ),
        isFalse,
      );
      expect(
        EInvoiceStatusInteraction.allowsTapForIssuance(
          IssuanceDisplayState.notIssued,
        ),
        isTrue,
      );
    });

    test('delivery sending maps to non-interactive', () {
      expect(
        EInvoiceStatusInteraction.allowsTapForDelivery(
          DeliveryDisplayState.sending,
        ),
        isFalse,
      );
      expect(
        EInvoiceStatusInteraction.allowsTapForDelivery(
          DeliveryDisplayState.notSent,
        ),
        isTrue,
      );
      expect(
        EInvoiceStatusInteraction.allowsTapForDelivery(
          DeliveryDisplayState.unknown,
        ),
        isTrue,
      );
    });
  });
}
