import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_einvoice_domain/domain.dart';

final class _FakeMeInvoiceProviderPort implements IMeInvoiceProviderPort {
  _FakeMeInvoiceProviderPort(this.outcome);

  final MeInvoicePreviewOutcome outcome;
  int calls = 0;
  Map<String, Object?>? lastCanonicalInvoice;

  @override
  Future<MeInvoiceAuthOutcome> authenticateAndListTemplates({
    required String tenantId,
    required String connectionId,
  }) async => throw UnimplementedError();

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
  Future<MeInvoiceIssuanceStatusOutcome> getStatus({
    required String tenantId,
    required String statusLookupKey,
    required String invoiceSeries,
    required String idempotencyKey,
    required String payloadHash,
    IssuanceProviderStatusLookup statusLookup =
        IssuanceProviderStatusLookup.providerTransactionId,
  }) => throw UnimplementedError();

  @override
  Future<MeInvoicePublishOutcome> publish({
    required String tenantId,
    required Map<String, Object?> canonicalInvoice,
    required String idempotencyKey,
  }) => throw UnimplementedError();
}

void main() {
  group('PreviewInvoiceCommandHandler', () {
    final sampleInvoice = <String, Object?>{
      'refId': 'ref-100',
      'invSeries': '1C25TYY',
      'signType': 2,
      'invDate': '2026-08-01',
      'totalAmount': 110000,
    };

    test('stores READY with the viewer ref', () async {
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
          providerConnectionId: 'conn-1',
          orderVersion: 1,
          canonicalInvoice: sampleInvoice,
        ),
      );

      expect(port.calls, 1);
      expect(gateway.stored, hasLength(1));
      expect(gateway.stored.single.status, 'READY');
      expect(
        gateway.stored.single.viewerRef,
        'https://meinvoice.vn/viewer/preview-123',
      );
      expect(gateway.stored.single.requestId, 'req-1');
    });

    test('records an auth failure as FAILED and does not retry', () async {
      final gateway = FakeInvoicePreviewGateway(requestId: 'req-1');
      final handler = PreviewInvoiceCommandHandler(
        providerPort: _FakeMeInvoiceProviderPort(
          const MeInvoicePreviewOutcome.authFailed(),
        ),
        previewGateway: gateway,
      );

      await handler.handle(
        PreviewInvoiceCommand(
          tenantId: 'tenant-1',
          salesOrderId: 'order-1',
          previewRequestId: 'req-1',
          providerConnectionId: 'conn-1',
          orderVersion: 1,
          canonicalInvoice: sampleInvoice,
        ),
      );

      expect(gateway.stored.single.status, 'FAILED');
      expect(gateway.stored.single.failureCode, 'PROVIDER_AUTH_FAILED');
      expect(gateway.stored.single.failureSource, FailureSource.provider);
    });

    test('leaves the row pending when MISA is unavailable', () async {
      final gateway = FakeInvoicePreviewGateway(requestId: 'req-1');
      final handler = PreviewInvoiceCommandHandler(
        providerPort: _FakeMeInvoiceProviderPort(
          const MeInvoicePreviewOutcome.providerUnavailable(),
        ),
        previewGateway: gateway,
      );

      expect(
        () => handler.handle(
          PreviewInvoiceCommand(
            tenantId: 'tenant-1',
            salesOrderId: 'order-1',
            previewRequestId: 'req-1',
            providerConnectionId: 'conn-1',
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
      expect(gateway.stored, isEmpty);
    });
  });
}
