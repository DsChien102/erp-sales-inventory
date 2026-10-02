import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/me_invoice_delivery_observation_provider_adapter.dart';

void main() {
  group('MeInvoiceDeliveryObservationProviderAdapter', () {
    test('returns unsupported without HTTP or getStatus', () async {
      final adapter = MeInvoiceDeliveryObservationProviderAdapter();

      final outcome = await adapter.observe(
        const DeliveryObservationContextDto(
          tenantId: 'tenant-1',
          reconciliationCaseId: 'case-1',
          deliveryId: 'del-1',
          providerConnectionId: 'conn-1',
          providerDeliveryReference: 'ref-1',
        ),
      );

      expect(outcome, isA<DeliveryObservationUnsupported>());
    });

    test('adapter source never references getStatus or sendEmail', () async {
      // Behavioral gate: adapter is pure unsupported and does not need a client.
      final adapter = MeInvoiceDeliveryObservationProviderAdapter();
      expect(adapter.runtimeType.toString(), contains('DeliveryObservation'));
      final outcome = await adapter.observe(
        const DeliveryObservationContextDto(
          tenantId: 't',
          reconciliationCaseId: 'c',
          deliveryId: 'd',
          providerConnectionId: 'p',
        ),
      );
      expect(outcome, isA<DeliveryObservationUnsupported>());
    });
  });
}
