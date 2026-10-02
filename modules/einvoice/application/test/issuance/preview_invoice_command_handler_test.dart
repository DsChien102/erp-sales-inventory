import 'dart:async';

import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_einvoice_domain/domain.dart';

void main() {
  group('PreviewInvoiceCommandHandler', () {
    const sampleInvoice = <String, Object?>{
      'invSeries': '1C25TYY',
      'signType': 2,
      'totalAmount': 110000,
    };

    test('stores READY with the viewer ref', () async {
      final previewGateway = FakeInvoicePreviewGateway(requestId: 'req-1');
      final providerPort = _FakeMeInvoiceProviderPort(
        outcome: const MeInvoicePreviewOutcome.success(
          viewerRef: 'https://viewer/1',
        ),
      );
      final handler = PreviewInvoiceCommandHandler(
        providerPort: providerPort,
        previewGateway: previewGateway,
      );

      await handler.handle(_command(sampleInvoice));

      expect(previewGateway.stored, hasLength(1));
      expect(previewGateway.stored.single.status, 'READY');
      expect(previewGateway.stored.single.viewerRef, 'https://viewer/1');
      expect(previewGateway.stored.single.requestId, 'req-1');
      expect(previewGateway.stored.single.salesOrderId, 'order-1');
    });

    test('records a data rejection as FAILED and does not retry', () async {
      final previewGateway = FakeInvoicePreviewGateway(requestId: 'req-1');
      final handler = PreviewInvoiceCommandHandler(
        providerPort: _FakeMeInvoiceProviderPort(
          outcome: const MeInvoicePreviewOutcome.invalidData(
            detail: 'Invalid_[Invoice.TaxRateInfo]',
          ),
        ),
        previewGateway: previewGateway,
      );

      await handler.handle(_command(sampleInvoice));

      expect(previewGateway.stored, hasLength(1));
      expect(previewGateway.stored.single.status, 'FAILED');
      expect(
        previewGateway.stored.single.failureCode,
        'PROVIDER_REJECTED_INVOICE_DATA',
      );
      expect(
        previewGateway.stored.single.failureSource,
        FailureSource.provider,
      );
      expect(
        previewGateway.stored.single.failureMessage,
        'Invalid_[Invoice.TaxRateInfo]',
      );
    });

    test('records an auth failure as FAILED', () async {
      final previewGateway = FakeInvoicePreviewGateway(requestId: 'req-1');
      final handler = PreviewInvoiceCommandHandler(
        providerPort: _FakeMeInvoiceProviderPort(
          outcome: const MeInvoicePreviewOutcome.authFailed(),
        ),
        previewGateway: previewGateway,
      );

      await handler.handle(_command(sampleInvoice));

      expect(previewGateway.stored.single.status, 'FAILED');
      expect(previewGateway.stored.single.failureCode, 'PROVIDER_AUTH_FAILED');
      expect(
        previewGateway.stored.single.failureSource,
        FailureSource.provider,
      );
    });

    test('leaves the row pending when MISA is unavailable', () async {
      final previewGateway = FakeInvoicePreviewGateway(requestId: 'req-1');
      final handler = PreviewInvoiceCommandHandler(
        providerPort: _FakeMeInvoiceProviderPort(
          outcome: const MeInvoicePreviewOutcome.providerUnavailable(),
        ),
        previewGateway: previewGateway,
      );

      expect(
        () => handler.handle(_command(sampleInvoice)),
        throwsA(isA<StateError>()),
      );
      expect(previewGateway.stored, isEmpty);
    });

    test('leaves the row pending when the call throws', () async {
      final previewGateway = FakeInvoicePreviewGateway(requestId: 'req-1');
      final handler = PreviewInvoiceCommandHandler(
        providerPort: _FakeMeInvoiceProviderPort(error: TimeoutException('misa')),
        previewGateway: previewGateway,
      );

      expect(
        () => handler.handle(_command(sampleInvoice)),
        throwsA(isA<TimeoutException>()),
      );
      expect(previewGateway.stored, isEmpty);
    });

    test('adds refId from the preview request id', () async {
      final providerPort = _FakeMeInvoiceProviderPort(
        outcome: const MeInvoicePreviewOutcome.success(
          viewerRef: 'https://viewer/1',
        ),
      );
      final handler = PreviewInvoiceCommandHandler(
        providerPort: providerPort,
        previewGateway: FakeInvoicePreviewGateway(requestId: 'req-1'),
      );

      await handler.handle(_command(sampleInvoice));

      expect(providerPort.lastCanonical?['refId'], 'req-1');
    });
  });
}

PreviewInvoiceCommand _command(Map<String, Object?> canonical) {
  return PreviewInvoiceCommand(
    tenantId: 'tenant-1',
    salesOrderId: 'order-1',
    previewRequestId: 'req-1',
    providerConnectionId: 'conn-1',
    orderVersion: 1,
    canonicalInvoice: canonical,
  );
}

final class _FakeMeInvoiceProviderPort implements IMeInvoiceProviderPort {
  _FakeMeInvoiceProviderPort({this.outcome, this.error});

  final MeInvoicePreviewOutcome? outcome;
  final Object? error;
  Map<String, Object?>? lastCanonical;

  @override
  Future<MeInvoiceAuthOutcome> authenticateAndListTemplates({
    required String tenantId,
    required String connectionId,
  }) => throw UnimplementedError();

  @override
  Future<MeInvoicePreviewOutcome> previewUnpublished({
    required String tenantId,
    required Map<String, Object?> canonicalInvoice,
  }) async {
    lastCanonical = canonicalInvoice;
    final thrown = error;
    if (thrown != null) {
      throw thrown;
    }
    return outcome!;
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
