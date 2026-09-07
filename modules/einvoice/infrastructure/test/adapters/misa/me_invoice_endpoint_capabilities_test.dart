import 'package:test/test.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/me_invoice_endpoint_capabilities.dart';

void main() {
  group('MeInvoiceEndpointCapabilities', () {
    test('testapi.meinvoice.vn allows emailDelivery when emailDeliveryEnabled is true', () {
      final caps = MeInvoiceEndpointCapabilities.resolve(
        baseUrl: Uri.parse('https://testapi.meinvoice.vn/api/integration'),
        emailDeliveryEnabled: true,
      );

      expect(caps.supportsEmailDelivery, isTrue);
      expect(
        caps.supportedDocumentTypes,
        equals({InvoiceDocumentType.pdf, InvoiceDocumentType.xml}),
      );
    });

    test('production HTTPS host allows emailDelivery only when emailDeliveryEnabled is true', () {
      final capsEnabled = MeInvoiceEndpointCapabilities.resolve(
        baseUrl: Uri.parse('https://api.meinvoice.vn/api/integration'),
        emailDeliveryEnabled: true,
      );
      expect(capsEnabled.supportsEmailDelivery, isTrue);

      final capsDisabled = MeInvoiceEndpointCapabilities.resolve(
        baseUrl: Uri.parse('https://api.meinvoice.vn/api/integration'),
        emailDeliveryEnabled: false,
      );
      expect(capsDisabled.supportsEmailDelivery, isFalse);
    });

    test('always advertises PDF and XML support', () {
      final caps = MeInvoiceEndpointCapabilities.resolve(
        baseUrl: Uri.parse('https://testapi.meinvoice.vn/api/integration'),
        emailDeliveryEnabled: false,
      );

      expect(caps.supportedDocumentTypes.contains(InvoiceDocumentType.pdf), isTrue);
      expect(caps.supportedDocumentTypes.contains(InvoiceDocumentType.xml), isTrue);
    });

    test('always advertises unpublished preview support', () {
      final testCaps = MeInvoiceEndpointCapabilities.resolve(
        baseUrl: Uri.parse('https://testapi.meinvoice.vn/api/integration'),
        emailDeliveryEnabled: false,
      );
      expect(testCaps.supportsPreview, isTrue);

      final prodCaps = MeInvoiceEndpointCapabilities.resolve(
        baseUrl: Uri.parse('https://api.meinvoice.vn/api/integration'),
        emailDeliveryEnabled: true,
      );
      expect(prodCaps.supportsPreview, isTrue);
    });

    test('rejects non-HTTPS base URLs', () {
      expect(
        () => MeInvoiceEndpointCapabilities.resolve(
          baseUrl: Uri.parse('http://api.meinvoice.vn/api/integration'),
          emailDeliveryEnabled: true,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
