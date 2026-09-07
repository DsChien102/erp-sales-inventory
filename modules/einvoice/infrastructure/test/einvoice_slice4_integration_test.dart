import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/worker_only_electronic_invoice_provider_port.dart';
import 'package:vet45_misa/e_invoice.dart';

import 'support/slice4_integration_harness.dart';

void main() {
  late Slice4TestHarness harness;

  setUp(() {
    harness = Slice4TestHarness()..setUp();
  });

  group('TH-08 Slice 4 end-to-end (fakes)', () {
    test(
      'official request/replay uses one operation, previewPublished once, AVAILABLE expires in 5m',
      () async {
        harness.fakeMeInvoiceClient.enqueuePreviewPublishedResult(
          MeInvoiceResult.ok('https://viewer.example/official'),
        );

        final pending = await harness.requestOfficialView();
        expect(pending.status, InvoiceDocumentStatus.pending);
        expect(
          harness.internalClient.countPending(
            FetchOfficialInvoiceViewCommand.type,
          ),
          1,
        );

        await harness.runWorker();

        expect(harness.fakeMeInvoiceClient.previewPublishedCount, 1);
        final op = harness.state.officialOps.values.single;
        expect(op.status, InvoiceDocumentStatus.available);
        expect(op.viewerUrl, 'https://viewer.example/official');
        expect(op.expiresAt, DateTime.utc(2026, 8, 31, 9, 5));

        final replay = await harness.requestOfficialView();
        expect(replay.operationId, op.operationId);
        expect(
          harness.internalClient.countPending(
            FetchOfficialInvoiceViewCommand.type,
          ),
          0,
        );
        expect(harness.fakeMeInvoiceClient.previewPublishedCount, 1);
      },
    );

    test(
      'official timeout twice marks same operation CHECK_REQUIRED; replay re-arms',
      () async {
        harness.fakeMeInvoiceClient.enqueuePreviewPublishedResult(
          const MeInvoiceResult.failed('meinvoice_network_timeout'),
        );
        harness.fakeMeInvoiceClient.enqueuePreviewPublishedResult(
          const MeInvoiceResult.failed('meinvoice_network_timeout'),
        );

        await harness.requestOfficialView();
        await harness.runWorker();
        await harness.runWorker();
        await harness.runWorker();

        final op = harness.state.officialOps.values.single;
        expect(op.status, InvoiceDocumentStatus.checkRequired);
        expect(op.generation, 1);

        harness.fakeMeInvoiceClient.enqueuePreviewPublishedResult(
          MeInvoiceResult.ok('https://viewer.example/replay'),
        );
        final replay = await harness.commandGateway.replayOfficialView(
          tenantId: Slice4TestHarness.tenantId,
          actorId: Slice4TestHarness.actorId,
          salesOrderId: Slice4TestHarness.salesOrderId,
        );
        expect(replay.operationId, op.operationId);
        expect(replay.status, InvoiceDocumentStatus.pending);

        await harness.runWorker();
        expect(op.status, InvoiceDocumentStatus.available);
        expect(harness.fakeMeInvoiceClient.previewPublishedCount, 3);
      },
    );

    test(
      'PDF request/replay downloads once, stores bytes once, records checksum',
      () async {
        final first = await harness.requestDocument(
          documentType: InvoiceDocumentType.pdf,
          idempotencyKey: 'idem-pdf-1',
        );
        expect(first.status, InvoiceDocumentStatus.pending);

        await harness.runWorker();

        expect(harness.fakeMeInvoiceClient.downloadCount, 1);
        expect(harness.state.storageUploadCount, 1);
        final op = harness.state.documentOps.values.single;
        expect(op.status, InvoiceDocumentStatus.available);
        expect(op.fileRef, isNotNull);
        expect(op.checksum, 'sha256-test');

        final replay = await harness.requestDocument(
          documentType: InvoiceDocumentType.pdf,
          idempotencyKey: 'idem-pdf-1',
        );
        expect(replay.operationId, op.operationId);
        expect(harness.fakeMeInvoiceClient.downloadCount, 1);
        expect(harness.state.storageUploadCount, 1);
      },
    );

    test('XML download uses XML data type and validates content', () async {
      final validXml = '<Invoice xmlns="http://example.test">ok</Invoice>';
      harness.fakeMeInvoiceClient.enqueueDownloadResult(
        MeInvoiceResult.ok([
          MeInvoiceInvoiceDataPublished(
            transactionId: 'tx-s4-1',
            data: validXml,
            bytes: validXml.codeUnits,
          ),
        ]),
      );

      await harness.requestDocument(
        documentType: InvoiceDocumentType.xml,
        idempotencyKey: 'idem-xml-1',
      );
      await harness.runWorker();

      expect(
        harness.fakeMeInvoiceClient.lastDownloadDataType,
        MeInvoiceDownloadDataType.xml,
      );
      expect(harness.state.storageUploadCount, 1);
    });

    test('unsupported PDF capability fails before enqueue', () async {
      harness.state.supportedDocumentTypes[Slice4TestHarness
          .providerConnectionId] = [
        'XML',
      ];

      await expectLater(
        harness.requestDocument(
          documentType: InvoiceDocumentType.pdf,
          idempotencyKey: 'idem-no-pdf',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'DOCUMENT_UNAVAILABLE',
          ),
        ),
      );
      expect(harness.internalClient.commands, isEmpty);
      expect(harness.fakeMeInvoiceClient.downloadCount, 0);
    });

    test(
      'same idempotency key with different intent -> IDEMPOTENCY_CONFLICT',
      () async {
        final op = Slice4DocumentOperation(
          operationId: 'op-conflict-1',
          tenantId: Slice4TestHarness.tenantId,
          electronicInvoiceId: Slice4TestHarness.electronicInvoiceId,
          salesOrderId: Slice4TestHarness.salesOrderId,
          documentType: InvoiceDocumentType.pdf,
          generation: 1,
          attemptOrdinal: 1,
          documentVersion: 0,
          providerConnectionId: Slice4TestHarness.providerConnectionId,
          idempotencyKey: 'shared-key',
          correlationId: 'corr-conflict',
          commandId: 'cmd-conflict-1',
          documentIntent: 'order-other:pdf',
        );
        harness.state.documentOps[op.operationId] = op;
        harness
                .state
                .documentOpsByIdempotency['${Slice4TestHarness.tenantId}:shared-key'] =
            op;

        await expectLater(
          harness.requestDocument(
            documentType: InvoiceDocumentType.xml,
            idempotencyKey: 'shared-key',
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              'IDEMPOTENCY_CONFLICT',
            ),
          ),
        );
      },
    );

    test('sales order out-of-scope returns NOT_FOUND without leak', () async {
      await expectLater(
        harness.commandBus.execute(
          RequestOfficialInvoiceViewCommand(
            tenantId: Slice4TestHarness.tenantId,
            actorId: Slice4TestHarness.actorId,
            salesOrderId: 'order-out-of-scope',
          ),
        ),
        throwsA(
          isA<StateError>().having((e) => e.message, 'message', 'NOT_FOUND'),
        ),
      );
      expect(harness.internalClient.commands, isEmpty);
      expect(harness.fakeMeInvoiceClient.previewPublishedCount, 0);
    });

    test(
      'definite empty document records FAILED; later request creates next generation',
      () async {
        harness.fakeMeInvoiceClient.enqueueDownloadResult(
          const MeInvoiceResult.failed('empty_data'),
        );

        final first = await harness.requestDocument(
          documentType: InvoiceDocumentType.pdf,
          idempotencyKey: 'idem-empty-1',
        );
        await harness.runWorker();

        final firstOp = harness.state.documentOps[first.operationId]!;
        expect(firstOp.status, InvoiceDocumentStatus.failed);

        harness.fakeMeInvoiceClient.enqueueDownloadResult(
          MeInvoiceResult.ok([
            MeInvoiceInvoiceDataPublished(
              transactionId: 'tx-s4-1',
              data: '%PDF-1.4',
              bytes: '%PDF-1.4'.codeUnits,
            ),
          ]),
        );

        final second = await harness.requestDocument(
          documentType: InvoiceDocumentType.pdf,
          idempotencyKey: 'idem-empty-2',
        );
        expect(second.operationId, isNot(first.operationId));
        await harness.runWorker();
        expect(
          harness.state.documentOps[second.operationId]!.status,
          InvoiceDocumentStatus.available,
        );
      },
    );

    test(
      'document timeout three times -> CHECK_REQUIRED, never FAILED',
      () async {
        harness.fakeMeInvoiceClient.enqueueDownloadResult(
          const MeInvoiceResult.failed('meinvoice_network_timeout'),
        );
        harness.fakeMeInvoiceClient.enqueueDownloadResult(
          const MeInvoiceResult.failed('meinvoice_network_timeout'),
        );
        harness.fakeMeInvoiceClient.enqueueDownloadResult(
          const MeInvoiceResult.failed('meinvoice_network_timeout'),
        );

        final requested = await harness.requestDocument(
          documentType: InvoiceDocumentType.pdf,
          idempotencyKey: 'idem-timeout',
        );
        await harness.runWorker();
        await harness.runWorker();
        await harness.runWorker();

        final op = harness.state.documentOps[requested.operationId]!;
        expect(op.status, InvoiceDocumentStatus.checkRequired);
        expect(op.status, isNot(InvoiceDocumentStatus.failed));
        expect(harness.state.storageUploadCount, 0);
      },
    );

    test('malformed bytes -> CHECK_REQUIRED without upload', () async {
      harness.fakeMeInvoiceClient.enqueueDownloadResult(
        MeInvoiceResult.ok([
          MeInvoiceInvoiceDataPublished(
            transactionId: 'tx-s4-1',
            data: 'not-a-pdf',
            bytes: 'not-a-pdf'.codeUnits,
          ),
        ]),
      );

      await harness.requestDocument(
        documentType: InvoiceDocumentType.pdf,
        idempotencyKey: 'idem-bad-bytes',
      );
      await harness.runWorker();

      expect(harness.state.storageUploadCount, 0);
      expect(
        harness.state.documentOps.values.single.status,
        InvoiceDocumentStatus.checkRequired,
      );
    });

    test('same observation triggerId replayed twice -> one command', () async {
      harness.commandGateway.enqueueObservation(
        tenantId: Slice4TestHarness.tenantId,
        electronicInvoiceId: Slice4TestHarness.electronicInvoiceId,
        triggerId: 'trigger-replay',
      );
      harness.commandGateway.enqueueObservation(
        tenantId: Slice4TestHarness.tenantId,
        electronicInvoiceId: Slice4TestHarness.electronicInvoiceId,
        triggerId: 'trigger-replay',
      );

      expect(
        harness.internalClient.commands
            .where((c) => c.commandType == PollProviderObservationCommand.type)
            .length,
        1,
      );
    });

    test(
      'two distinct triggerIds same day -> two auditable observation commands',
      () async {
        harness.commandGateway.enqueueObservation(
          tenantId: Slice4TestHarness.tenantId,
          electronicInvoiceId: Slice4TestHarness.electronicInvoiceId,
          triggerId: 'trigger-a',
        );
        harness.commandGateway.enqueueObservation(
          tenantId: Slice4TestHarness.tenantId,
          electronicInvoiceId: Slice4TestHarness.electronicInvoiceId,
          triggerId: 'trigger-b',
        );

        harness.fakeMeInvoiceClient.enqueueGetStatusResult(
          const MeInvoiceResult.ok([
            MeInvoiceInvoiceStatus(
              transactionId: 'tx-s4-1',
              publishStatus: 1,
              invNo: '0000001',
            ),
          ]),
        );
        harness.fakeMeInvoiceClient.enqueueGetStatusResult(
          const MeInvoiceResult.ok([
            MeInvoiceInvoiceStatus(
              transactionId: 'tx-s4-1',
              publishStatus: 1,
              invNo: '0000002',
            ),
          ]),
        );

        await harness.runWorker();
        await harness.runWorker();

        expect(harness.fakeMeInvoiceClient.getStatusCount, 2);
        expect(harness.state.observations, hasLength(2));
        expect(harness.interactionGateway.startCount, 2);
      },
    );

    test(
      'observation success -> one interaction and one observation',
      () async {
        harness.commandGateway.enqueueObservation(
          tenantId: Slice4TestHarness.tenantId,
          electronicInvoiceId: Slice4TestHarness.electronicInvoiceId,
          triggerId: 'trigger-success',
        );
        harness.fakeMeInvoiceClient.enqueueGetStatusResult(
          const MeInvoiceResult.ok([
            MeInvoiceInvoiceStatus(
              transactionId: 'tx-s4-1',
              publishStatus: 1,
              invNo: '0000001',
            ),
          ]),
        );

        await harness.runWorker();

        expect(harness.state.observations, hasLength(1));
        expect(harness.interactionGateway.startCount, 1);
        expect(harness.state.attentionEvents, isEmpty);
      },
    );

    test(
      'observation timeout -> interaction only, no observation row',
      () async {
        harness.commandGateway.enqueueObservation(
          tenantId: Slice4TestHarness.tenantId,
          electronicInvoiceId: Slice4TestHarness.electronicInvoiceId,
          triggerId: 'trigger-timeout',
        );
        harness.fakeMeInvoiceClient.enqueueGetStatusResult(
          const MeInvoiceResult.failed('meinvoice_network_timeout'),
        );

        await harness.runWorker();

        expect(harness.state.observations, isEmpty);
        expect(harness.interactionGateway.startCount, 1);
        expect(
          harness.state.interactionsByCorrelation.values.single.outcome,
          ProviderInteractionOutcome.timeout,
        );
      },
    );

    test('observation NOT_FOUND emits attention outbox event', () async {
      harness.commandGateway.enqueueObservation(
        tenantId: Slice4TestHarness.tenantId,
        electronicInvoiceId: Slice4TestHarness.electronicInvoiceId,
        triggerId: 'trigger-not-found',
      );
      harness.fakeMeInvoiceClient.enqueueGetStatusResult(
        const MeInvoiceResult.ok(<MeInvoiceInvoiceStatus>[]),
      );

      await harness.runWorker();

      expect(harness.state.observations, hasLength(1));
      expect(harness.state.observations.single.providerStateCode, 'NOT_FOUND');
      expect(harness.state.attentionEvents, hasLength(1));
    });

    test('permission denial returns no durable worker enqueue', () async {
      harness.state.permittedActors.clear();

      await expectLater(
        harness.requestOfficialView(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'PERMISSION_DENIED',
          ),
        ),
      );
      expect(harness.internalClient.commands, isEmpty);
    });

    test(
      'ERP worker-only guard rejects MISA HTTP on electronic invoice port',
      () async {
        final guard = WorkerOnlyElectronicInvoiceProviderPort();
        await expectLater(
          guard.fetchOfficialView(
            const ElectronicInvoiceProviderContextDto(
              tenantId: Slice4TestHarness.tenantId,
              providerConnectionId: Slice4TestHarness.providerConnectionId,
              electronicInvoiceId: Slice4TestHarness.electronicInvoiceId,
              providerInvoiceReference: 'tx-s4-1',
              invoiceSeries: '1C26TYY',
              operationId: 'op-1',
            ),
          ),
          throwsA(isA<StateError>()),
        );
      },
    );
  });
}
