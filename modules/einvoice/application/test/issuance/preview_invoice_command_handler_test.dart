import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_application/testing.dart';

void main() {
  group('PreviewInvoiceCommandHandler', () {
    final sampleInvoice = <String, Object?>{
      'refId': 'ref-100',
      'invSeries': '1C25TYY',
      'signType': 2,
      'totalAmount': 110000,
    };

    test('uses distinct provider-call correlation per worker attempt', () async {
      final previewGateway = FakeInvoicePreviewGateway(requestId: 'req-1');
      final interactionGateway = FakeProviderInteractionGateway();
      final providerPort = _FakeMeInvoiceProviderPort(
        const MeInvoicePreviewOutcome.success(viewerRef: 'https://viewer/1'),
      );

      final handler = PreviewInvoiceCommandHandler(
        providerPort: providerPort,
        previewGateway: previewGateway,
        interactionGateway: interactionGateway,
      );

      await handler.handle(
        PreviewInvoiceCommand(
          id: 'cmd-preview-1',
          tenantId: 'tenant-1',
          salesOrderId: 'order-1',
          previewRequestId: 'req-1',
          providerConnectionId: 'conn-1',
          orderVersion: 1,
          canonicalInvoice: sampleInvoice,
          workerAttemptNumber: 1,
        ),
      );

      await handler.handle(
        PreviewInvoiceCommand(
          id: 'cmd-preview-1',
          tenantId: 'tenant-1',
          salesOrderId: 'order-1',
          previewRequestId: 'req-1',
          providerConnectionId: 'conn-1',
          orderVersion: 1,
          canonicalInvoice: sampleInvoice,
          workerAttemptNumber: 2,
        ),
      );

      expect(interactionGateway.startCalls, hasLength(2));
      expect(
        interactionGateway.startCalls[0].correlationId,
        isNot(interactionGateway.startCalls[1].correlationId),
      );
    });
  });
}

final class _FakeMeInvoiceProviderPort implements IMeInvoiceProviderPort {
  _FakeMeInvoiceProviderPort(this.outcome);

  final MeInvoicePreviewOutcome outcome;

  @override
  Future<MeInvoiceAuthOutcome> authenticateAndListTemplates({
    required String tenantId,
    required String connectionId,
  }) => throw UnimplementedError();

  @override
  Future<MeInvoicePreviewOutcome> previewUnpublished({
    required String tenantId,
    required Map<String, Object?> canonicalInvoice,
  }) async => outcome;

  @override
  void validateCanonical({required Map<String, Object?> canonicalInvoice}) {}

  @override
  Future<MeInvoiceIssuanceStatusOutcome> getStatus({
    required String tenantId,
    required String statusLookupKey,
    required String invoiceSeries,
    required String idempotencyKey,
    required String payloadHash,
    IssuanceProviderStatusLookup statusLookup = IssuanceProviderStatusLookup.providerTransactionId,
  }) => throw UnimplementedError();

  @override
  Future<MeInvoicePublishOutcome> publish({
    required String tenantId,
    required Map<String, Object?> canonicalInvoice,
    required String idempotencyKey,
  }) => throw UnimplementedError();
}
