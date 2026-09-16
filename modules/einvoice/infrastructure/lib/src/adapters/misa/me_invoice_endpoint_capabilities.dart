import 'package:vet45_einvoice_domain/domain.dart';

/// Pure capability resolver for MISA meInvoice endpoints.
final class MeInvoiceEndpointCapabilities {
  const MeInvoiceEndpointCapabilities({
    required this.supportsEmailDelivery,
    required this.supportedDocumentTypes,
    required this.supportsPreview,
  });

  final bool supportsEmailDelivery;
  final Set<InvoiceDocumentType> supportedDocumentTypes;

  /// MISA meInvoice exposes `/invoice/unpublishview` on both prod and testapi.
  final bool supportsPreview;

  /// Pure capability resolution based on baseUrl host and explicit emailDeliveryEnabled configuration.
  static MeInvoiceEndpointCapabilities resolve({
    required Uri baseUrl,
    required bool emailDeliveryEnabled,
  }) {
    if (!baseUrl.hasScheme || baseUrl.scheme.toLowerCase() != 'https') {
      throw ArgumentError.value(
        baseUrl.toString(),
        'baseUrl',
        'MISA endpoint baseUrl must use HTTPS',
      );
    }

    // Product host only: testapi never advertises email delivery.
    final emailSupported =
        emailDeliveryEnabled &&
        baseUrl.host.toLowerCase() == 'api.meinvoice.vn';

    return MeInvoiceEndpointCapabilities(
      supportsEmailDelivery: emailSupported,
      supportedDocumentTypes: const {
        InvoiceDocumentType.pdf,
        InvoiceDocumentType.xml,
      },
      supportsPreview: true,
    );
  }
}
