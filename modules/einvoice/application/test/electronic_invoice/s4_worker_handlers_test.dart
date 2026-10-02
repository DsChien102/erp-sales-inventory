import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 's4_test_support.dart';

void main() {
  group('S4 worker command serialization', () {
    test('FetchOfficialInvoiceViewCommand round-trips without row id', () {
      final command = FetchOfficialInvoiceViewCommand(
        id: 'cmd-official-1',
        tenantId: 'tenant-1',
        electronicInvoiceId: 'ei-1',
        requestId: 'req-1',
        correlationId: 'corr-1',
      );

      final payload = command.toJson();
      expect(payload.containsKey('id'), isFalse);
      expect(payload.containsKey(internalCommandWorkerAttemptNumberKey), isFalse);

      final restored = FetchOfficialInvoiceViewCommand.fromJson(payload, id: 'cmd-official-1');
      expect(restored.commandType, FetchOfficialInvoiceViewCommand.type);
      expect(restored.requestId, 'req-1');
      expect(restored.workerAttemptNumber, 1);
    });

    test('DownloadInvoiceDocumentCommand round-trips document type wire values', () {
      final command = DownloadInvoiceDocumentCommand(
        id: 'cmd-doc-1',
        tenantId: 'tenant-1',
        electronicInvoiceId: 'ei-1',
        documentType: InvoiceDocumentType.xml,
        requestId: 'req-doc-1',
        correlationId: 'corr-doc-1',
      );

      final restored = DownloadInvoiceDocumentCommand.fromJson(
        command.toJson(),
        id: 'cmd-doc-1',
      );
      expect(restored.documentType, InvoiceDocumentType.xml);
      expect(restored.requestId, 'req-doc-1');
    });

    test('PollProviderObservationCommand rejects blank triggerId', () {
      expect(
        () => PollProviderObservationCommand.fromJson(
          {
            'tenant_id': 'tenant-1',
            'provider_connection_id': 'conn-1',
            'electronic_invoice_id': 'ei-1',
            'trigger_id': '  ',
            'correlation_id': 'corr-1',
          },
          id: 'cmd-obs-1',
        ),
        throwsFormatException,
      );
    });

    test('distinct triggerIds remain distinct commands on same date', () {
      final first = PollProviderObservationCommand(
        id: 'cmd-obs-a',
        tenantId: 'tenant-1',
        providerConnectionId: 'conn-1',
        electronicInvoiceId: 'ei-1',
        triggerId: 'trigger-a',
        correlationId: 'corr-a',
      );
      final second = PollProviderObservationCommand(
        id: 'cmd-obs-b',
        tenantId: 'tenant-1',
        providerConnectionId: 'conn-1',
        electronicInvoiceId: 'ei-1',
        triggerId: 'trigger-b',
        correlationId: 'corr-b',
      );

      expect(first.toJson()['trigger_id'], isNot(second.toJson()['trigger_id']));
      expect(first.id, isNot(second.id));
    });

    test('worker attempt number is read from reserved runtime key only', () {
      final payload = FetchOfficialInvoiceViewCommand(
        id: 'cmd-1',
        tenantId: 'tenant-1',
        electronicInvoiceId: 'ei-1',
        requestId: 'req-1',
        correlationId: 'corr-1',
        workerAttemptNumber: 1,
      ).toJson();

      final withAttempt = Map<String, dynamic>.from(payload)
        ..[internalCommandWorkerAttemptNumberKey] = 2;

      final restored = FetchOfficialInvoiceViewCommand.fromJson(withAttempt, id: 'cmd-1');
      expect(restored.workerAttemptNumber, 2);
      expect(restored.toJson().containsKey(internalCommandWorkerAttemptNumberKey), isFalse);
    });

    test('provider-call correlation differs per worker attempt', () {
      final first = ProviderCallCorrelationId.forWorkerAttempt(
        commandId: 'cmd-1',
        workerAttemptNumber: 1,
      );
      final second = ProviderCallCorrelationId.forWorkerAttempt(
        commandId: 'cmd-1',
        workerAttemptNumber: 2,
      );

      expect(first, isNot(second));
    });
  });

  group('FetchOfficialInvoiceViewCommandHandler', () {
    OfficialViewOperationContextDto pendingContext() {
      return const OfficialViewOperationContextDto(
        tenantId: 'tenant-1',
        electronicInvoiceId: 'ei-1',
        requestId: 'req-1',
        status: InvoiceDocumentStatus.pending,
        providerConnectionId: 'conn-1',
        providerInvoiceReference: 'ref-1',
        invoiceSeries: '1C26TYY',
      );
    }

    FetchOfficialInvoiceViewCommand pendingCommand({required String id}) {
      return FetchOfficialInvoiceViewCommand(
        id: id,
        tenantId: 'tenant-1',
        electronicInvoiceId: 'ei-1',
        requestId: 'req-1',
        correlationId: 'corr-1',
      );
    }

    test('records AVAILABLE on success without an interaction log', () async {
      final commandGateway = StubOfficialViewCommandGateway();
      commandGateway.officialViewContext = pendingContext();

      final providerPort = StubElectronicInvoiceProviderPort();
      providerPort.officialOutcome = OfficialViewProviderSuccess(
        viewerUrl: 'https://viewer.example/invoice',
        expiresAt: DateTime.utc(2026, 8, 31, 9, 5),
        providerReference: 'tx-1',
      );

      final handler = FetchOfficialInvoiceViewCommandHandler(
        commandGateway: commandGateway,
        providerPort: providerPort,
      );

      await handler.handle(pendingCommand(id: 'cmd-official-1'));

      expect(providerPort.fetchOfficialViewCalls, 1);
      expect(commandGateway.lastOfficialViewResult?.status, InvoiceDocumentStatus.available);
      expect(commandGateway.lastOfficialViewResult?.viewerUrl, 'https://viewer.example/invoice');
      expect(commandGateway.lastOfficialViewResult?.requestId, 'req-1');
    });

    test('MISA ambiguous throws and does not record a result', () async {
      final commandGateway = StubOfficialViewCommandGateway();
      commandGateway.officialViewContext = pendingContext();

      final providerPort = StubElectronicInvoiceProviderPort();
      providerPort.officialOutcome = const OfficialViewProviderAmbiguous(
        safeErrorCode: 'PROVIDER_TIMEOUT',
      );

      final handler = FetchOfficialInvoiceViewCommandHandler(
        commandGateway: commandGateway,
        providerPort: providerPort,
      );

      await expectLater(
        handler.handle(pendingCommand(id: 'cmd-official-2')),
        throwsA(isA<StateError>()),
      );

      expect(commandGateway.lastOfficialViewResult, isNull);
    });

    test('MISA definite failure records a provider failure source', () async {
      final commandGateway = StubOfficialViewCommandGateway();
      commandGateway.officialViewContext = pendingContext();

      final providerPort = StubElectronicInvoiceProviderPort();
      providerPort.officialOutcome = const OfficialViewProviderDefiniteFailure(
        failureCode: 'INVOICE_NOT_FOUND',
        failureMessage: 'Invoice missing at provider',
      );

      final handler = FetchOfficialInvoiceViewCommandHandler(
        commandGateway: commandGateway,
        providerPort: providerPort,
      );

      await handler.handle(pendingCommand(id: 'cmd-official-3'));

      expect(commandGateway.lastOfficialViewResult?.status, InvoiceDocumentStatus.failed);
      expect(
        commandGateway.lastOfficialViewResult?.failureSource,
        FailureSource.provider,
      );
      expect(commandGateway.lastOfficialViewResult?.failureCode, 'INVOICE_NOT_FOUND');
    });
  });

  group('DownloadInvoiceDocumentCommandHandler', () {
    InvoiceDocumentOperationContextDto pendingContext() {
      return const InvoiceDocumentOperationContextDto(
        tenantId: 'tenant-1',
        electronicInvoiceId: 'ei-1',
        documentType: InvoiceDocumentType.pdf,
        requestId: 'req-doc-1',
        status: InvoiceDocumentStatus.pending,
        providerConnectionId: 'conn-1',
        providerInvoiceReference: 'ref-1',
        invoiceSeries: '1C26TYY',
      );
    }

    DownloadInvoiceDocumentCommand pendingCommand() {
      return DownloadInvoiceDocumentCommand(
        id: 'cmd-doc-1',
        tenantId: 'tenant-1',
        electronicInvoiceId: 'ei-1',
        documentType: InvoiceDocumentType.pdf,
        requestId: 'req-doc-1',
        correlationId: 'req-doc-1',
      );
    }

    test('MISA ambiguous throws and does not record a result', () async {
      final commandGateway = StubDocumentCommandGateway();
      commandGateway.documentContext = pendingContext();
      final providerPort = StubElectronicInvoiceProviderPort();
      providerPort.documentOutcome = const InvoiceDocumentProviderAmbiguous(
        safeErrorCode: 'PROVIDER_TIMEOUT',
      );

      final handler = DownloadInvoiceDocumentCommandHandler(
        commandGateway: commandGateway,
        providerPort: providerPort,
        storagePort: _UnusedDocumentStorage(),
      );

      await expectLater(
        handler.handle(pendingCommand()),
        throwsA(isA<StateError>()),
      );
      expect(commandGateway.lastDocumentResult, isNull);
    });

    test('MISA definite failure records a provider failure source', () async {
      final commandGateway = StubDocumentCommandGateway();
      commandGateway.documentContext = pendingContext();
      final providerPort = StubElectronicInvoiceProviderPort();
      providerPort.documentOutcome = const InvoiceDocumentProviderDefiniteFailure(
        failureCode: 'DOCUMENT_EMPTY',
        failureMessage: 'Provider returned no bytes',
      );

      final handler = DownloadInvoiceDocumentCommandHandler(
        commandGateway: commandGateway,
        providerPort: providerPort,
        storagePort: _UnusedDocumentStorage(),
      );

      await handler.handle(pendingCommand());

      expect(commandGateway.lastDocumentResult?.status, InvoiceDocumentStatus.failed);
      expect(commandGateway.lastDocumentResult?.failureSource, FailureSource.provider);
      expect(commandGateway.lastDocumentResult?.failureCode, 'DOCUMENT_EMPTY');
    });
  });

  group('PreviewInvoiceCommandHandler interaction audit', () {
    final sampleInvoice = <String, Object?>{
      'refId': 'ref-100',
      'invSeries': '1C25TYY',
      'signType': 2,
      'totalAmount': 110000,
    };

    test('stores READY with the viewer ref', () async {
      final previewGateway = FakeInvoicePreviewGateway(requestId: 'req-1');
      final providerPort = _PreviewProviderPort(
        const MeInvoicePreviewOutcome.success(
          viewerRef: 'https://meinvoice.vn/viewer/preview-123',
        ),
      );

      final handler = PreviewInvoiceCommandHandler(
        providerPort: providerPort,
        previewGateway: previewGateway,
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

      expect(previewGateway.stored, hasLength(1));
      expect(previewGateway.stored.single.status, 'READY');
      expect(
        previewGateway.stored.single.viewerRef,
        'https://meinvoice.vn/viewer/preview-123',
      );
    });
  });
}

final class _PreviewProviderPort implements IMeInvoiceProviderPort {
  _PreviewProviderPort(this.outcome);

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

final class _UnusedDocumentStorage implements IInvoiceDocumentStoragePort {
  @override
  Future<StoredInvoiceDocumentDto> store({
    required String tenantId,
    required String electronicInvoiceId,
    required InvoiceDocumentType documentType,
    required int documentVersion,
    required List<int> bytes,
  }) => throw UnimplementedError();
}
