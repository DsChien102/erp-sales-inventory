import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/me_invoice_observation_classifier.dart';
import 'package:vet45_misa/e_invoice.dart';

void main() {
  group('MeInvoiceObservationClassifier', () {
    test('uses UNKNOWN labels for unrecognized numeric states', () {
      final outcome = MeInvoiceObservationClassifier.classify(
        result: MeInvoiceResult.ok([
          const MeInvoiceInvoiceStatus(
            transactionId: 'tx-1',
            publishStatus: 99,
            eInvoiceStatus: 88,
          ),
        ]),
        providerInvoiceReference: 'tx-1',
        now: DateTime.utc(2026, 8, 31, 9),
      );

      expect(outcome, isA<ProviderObservationFound>());
      final found = outcome as ProviderObservationFound;
      expect(found.providerStateCode, 'PS_99_ES_88');
      expect(found.safeDescription, 'UNKNOWN_99');
    });
  });
}
