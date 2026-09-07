import 'package:vet45_einvoice_domain/domain.dart';
import 'package:test/test.dart';

void main() {
  test('capability snapshot distinguishes PDF and XML support', () {
    const snapshot = ProviderCapabilitiesSnapshot(
      supportsEmailDelivery: true,
      templateCount: 1,
      supportedDocumentTypes: {InvoiceDocumentType.pdf},
    );
    expect(snapshot.supports(InvoiceDocumentType.pdf), isTrue);
    expect(snapshot.supports(InvoiceDocumentType.xml), isFalse);
  });

  test('missing supportedDocumentTypes defaults to empty set', () {
    const snapshot = ProviderCapabilitiesSnapshot(
      supportsEmailDelivery: false,
      templateCount: 0,
    );
    expect(snapshot.supportedDocumentTypes, isEmpty);
    expect(snapshot.supports(InvoiceDocumentType.pdf), isFalse);
    expect(snapshot.supports(InvoiceDocumentType.xml), isFalse);
  });

  test('supportsDeliveryResultObservation defaults fail-closed to false', () {
    const snapshot = ProviderCapabilitiesSnapshot(
      supportsEmailDelivery: true,
      templateCount: 1,
    );
    expect(snapshot.supportsDeliveryResultObservation, isFalse);
  });

  test('copyWith preserves supportedDocumentTypes', () {
    const snapshot = ProviderCapabilitiesSnapshot(
      supportsEmailDelivery: true,
      templateCount: 2,
      supportedDocumentTypes: {InvoiceDocumentType.pdf, InvoiceDocumentType.xml},
    );
    final copied = snapshot.copyWith(templateCount: 3);
    expect(copied.supportedDocumentTypes, snapshot.supportedDocumentTypes);
    expect(copied.templateCount, 3);
  });

  test('supportsPreview defaults fail-closed to false', () {
    const snapshot = ProviderCapabilitiesSnapshot(
      supportsEmailDelivery: true,
      templateCount: 1,
    );
    expect(snapshot.supportsPreview, isFalse);
  });

  test('copyWith can set supportsPreview', () {
    const snapshot = ProviderCapabilitiesSnapshot(
      supportsEmailDelivery: true,
      templateCount: 1,
    );
    final copied = snapshot.copyWith(supportsPreview: true);
    expect(copied.supportsPreview, isTrue);
    expect(snapshot.supportsPreview, isFalse);
  });
}
