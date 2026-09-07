import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';

import 's4_test_support.dart';

void main() {
  group('S4 public handler orchestration', () {
    test('SCN-E03-U01-FR06-01 request official view -> PENDING + operationId', () async {
      final gateway = RecordingElectronicInvoiceCommandGateway();
      final handler = RequestOfficialInvoiceViewCommandHandler(gateway: gateway);

      final result = await handler.handle(
        RequestOfficialInvoiceViewCommand(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
        ),
      );

      expect(gateway.officialViewRequests.single, (
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: 'order-1',
      ));
      expect(result.operationId, 'op-official-1');
      expect(result.status, InvoiceDocumentStatus.pending);
    });

    test('SCN-E03-U02-FR03-01 request PDF -> PENDING + operationId', () async {
      final gateway = RecordingElectronicInvoiceCommandGateway();
      final handler = RequestInvoiceDocumentCommandHandler(gateway: gateway);

      final result = await handler.handle(
        RequestInvoiceDocumentCommand(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
          documentType: InvoiceDocumentType.pdf,
          idempotencyKey: 'idem-1',
        ),
      );

      expect(gateway.documentRequests.single.documentType, InvoiceDocumentType.pdf);
      expect(result.operationId, 'op-doc-1');
      expect(result.status, InvoiceDocumentStatus.pending);
    });

    test('read queries delegate tenant actor salesOrderId', () async {
      final gateway = RecordingElectronicInvoiceReadGateway();
      final detailHandler = GetElectronicInvoiceDetailQueryHandler(gateway: gateway);
      final documentsHandler = GetInvoiceDocumentsQueryHandler(gateway: gateway);
      final observationHandler = GetLatestProviderObservationQueryHandler(
        gateway: gateway,
      );

      await detailHandler.handle(
        GetElectronicInvoiceDetailQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
        ),
      );
      await documentsHandler.handle(
        GetInvoiceDocumentsQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
        ),
      );
      await observationHandler.handle(
        GetLatestProviderObservationQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
        ),
      );

      expect(gateway.lastTenantId, 'tenant-1');
      expect(gateway.lastActorId, 'actor-1');
      expect(gateway.lastSalesOrderId, 'order-1');
    });
  });

  group('ProviderInteractionRecord wire mapping', () {
    test('maps canonical wire values', () {
      expect(
        ProviderInteractionDirection.fromWire('OUTBOUND'),
        ProviderInteractionDirection.outbound,
      );
      expect(ProviderInteractionDirection.outbound.toWire(), 'OUTBOUND');
      expect(
        ProviderInteractionStatus.fromWire('COMPLETED'),
        ProviderInteractionStatus.completed,
      );
      expect(
        ProviderInteractionOutcome.fromWire('TIMEOUT'),
        ProviderInteractionOutcome.timeout,
      );
    });

    test('rejects unknown wire values', () {
      expect(
        () => ProviderInteractionDirection.fromWire('SIDEWAYS'),
        throwsArgumentError,
      );
      expect(
        () => ProviderInteractionOutcome.fromWire('FABRICATED'),
        throwsArgumentError,
      );
    });

    test('enforces started/completed lifecycle', () {
      final started = ProviderInteractionRecord(
        interactionReference: 'int-1',
        tenantId: 'tenant-1',
        version: 0,
        providerConnectionId: 'conn-1',
        direction: ProviderInteractionDirection.outbound,
        operationType: 'einvoice.fetch_official_view',
        targetType: 'OFFICIAL_VIEW_OPERATION',
        targetId: 'op-1',
        correlationId: 'corr-1',
        requestReference: 'cmd-1',
        status: ProviderInteractionStatus.started,
        startedAt: DateTime.utc(2026, 8, 31),
      );
      expect(started.outcome, isNull);

      expect(
        () => ProviderInteractionRecord(
          interactionReference: 'int-2',
          tenantId: 'tenant-1',
          version: 1,
          providerConnectionId: 'conn-1',
          direction: ProviderInteractionDirection.outbound,
          operationType: 'einvoice.fetch_official_view',
          targetType: 'OFFICIAL_VIEW_OPERATION',
          targetId: 'op-1',
          correlationId: 'corr-2',
          requestReference: 'cmd-2',
          status: ProviderInteractionStatus.completed,
          startedAt: DateTime.utc(2026, 8, 31),
        ),
        throwsArgumentError,
      );
    });
  });
}
