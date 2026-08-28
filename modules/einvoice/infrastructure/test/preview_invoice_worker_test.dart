import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_application/testing.dart';

final class _FakeMeInvoiceProviderPort implements IMeInvoiceProviderPort {
  _FakeMeInvoiceProviderPort(this.outcome);

  final MeInvoicePreviewOutcome outcome;
  int calls = 0;
  Map<String, Object?>? lastCanonicalInvoice;

  @override
  Future<MeInvoiceAuthOutcome> authenticateAndListTemplates({
    required String tenantId,
    required String connectionId,
  }) async =>
      throw UnimplementedError();

  @override
  Future<MeInvoicePreviewOutcome> previewUnpublished({
    required String tenantId,
    required Map<String, Object?> canonicalInvoice,
  }) async {
    calls++;
    lastCanonicalInvoice = canonicalInvoice;
    return outcome;
  }

  @override
  void validateCanonical({required Map<String, Object?> canonicalInvoice}) {}

  @override
  Future<MeInvoicePublishOutcome> publish({
    required String tenantId,
    required Map<String, Object?> canonicalInvoice,
    required String idempotencyKey,
  }) =>
      throw UnimplementedError();
}

void main() {
  group('PreviewInvoiceCommandHandler', () {
    final sampleInvoice = <String, Object?>{
      'refId': 'ref-100',
      'invSeries': '1C25TYY',
      'invDate': '2026-08-01',
      'totalAmount': 110000,
    };

    test('stores viewerRef on MISA preview success', () async {
      final gateway = FakeInvoicePreviewGateway(requestId: 'req-1');
      final port = _FakeMeInvoiceProviderPort(
        const MeInvoicePreviewOutcome.success(
          viewerRef: 'https://meinvoice.vn/viewer/preview-123',
        ),
      );

      final handler = PreviewInvoiceCommandHandler(
        providerPort: port,
        previewGateway: gateway,
      );

      await handler.handle(
        PreviewInvoiceCommand(
          tenantId: 'tenant-1',
          salesOrderId: 'order-1',
          previewRequestId: 'req-1',
          orderVersion: 1,
          canonicalInvoice: sampleInvoice,
        ),
      );

      expect(port.calls, 1);
      expect(port.lastCanonicalInvoice, sampleInvoice);
      expect(gateway.storedRequestId, 'req-1');
    });

    test('throws PROVIDER_NOT_CONNECTED when auth fails', () async {
      final gateway = FakeInvoicePreviewGateway(requestId: 'req-1');
      final port = _FakeMeInvoiceProviderPort(
        const MeInvoicePreviewOutcome.authFailed(),
      );

      final handler = PreviewInvoiceCommandHandler(
        providerPort: port,
        previewGateway: gateway,
      );

      expect(
        () => handler.handle(
          PreviewInvoiceCommand(
            tenantId: 'tenant-1',
            salesOrderId: 'order-1',
            previewRequestId: 'req-1',
            orderVersion: 1,
            canonicalInvoice: sampleInvoice,
          ),
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'PROVIDER_NOT_CONNECTED',
          ),
        ),
      );
      expect(gateway.storedRequestId, isNull);
    });

    test('throws PROVIDER_UNAVAILABLE when provider unavailable', () async {
      final gateway = FakeInvoicePreviewGateway(requestId: 'req-1');
      final port = _FakeMeInvoiceProviderPort(
        const MeInvoicePreviewOutcome.providerUnavailable(),
      );

      final handler = PreviewInvoiceCommandHandler(
        providerPort: port,
        previewGateway: gateway,
      );

      expect(
        () => handler.handle(
          PreviewInvoiceCommand(
            tenantId: 'tenant-1',
            salesOrderId: 'order-1',
            previewRequestId: 'req-1',
            orderVersion: 1,
            canonicalInvoice: sampleInvoice,
          ),
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'PROVIDER_UNAVAILABLE',
          ),
        ),
      );
      expect(gateway.storedRequestId, isNull);
    });
  });
}
