import 'package:vet45_einvoice_domain/domain.dart';
import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_application/testing.dart';

void main() {
  group('EP-03 fake scenarios', () {
    test('official_view_ok returns viewer URL', () async {
      final module = FakeEInvoiceModule(scenario: FakeEInvoiceScenario.officialViewOk);
      final result = await module.executeCommandAsync(
        RequestOfficialInvoiceViewCommand(
          tenantId: 't1',
          actorId: 'a1',
          salesOrderId: 'so-1',
        ),
      );
      expect(result.viewerUrl, isNotNull);
    });

    test('download_pdf_ok resolves signed URL from documents query', () async {
      final module = FakeEInvoiceModule(scenario: FakeEInvoiceScenario.downloadPdfOk);
      final request = await module.executeCommandAsync(
        RequestInvoiceDocumentCommand(
          tenantId: 't1',
          actorId: 'a1',
          salesOrderId: 'so-1',
          documentType: InvoiceDocumentType.pdf,
          idempotencyKey: 'doc-1',
        ),
      );
      expect(request.operationId, isNotEmpty);
      expect(request.status, InvoiceDocumentStatus.pending);
      expect(request.downloadUrl, isNull);

      final documents = await module.executeQueryAsync(
        GetInvoiceDocumentsQuery(
          tenantId: 't1',
          actorId: 'a1',
          salesOrderId: 'so-1',
        ),
      );
      expect(documents.pdf?.operationId, request.operationId);
      expect(documents.pdf?.status, InvoiceDocumentStatus.available);
      expect(documents.pdf?.downloadUrl, isNotEmpty);
      expect(documents.pdf?.checksum, isNotEmpty);
    });

    test('download_xml_ok resolves signed URL from documents query', () async {
      final module = FakeEInvoiceModule(scenario: FakeEInvoiceScenario.downloadXmlOk);
      final request = await module.executeCommandAsync(
        RequestInvoiceDocumentCommand(
          tenantId: 't1',
          actorId: 'a1',
          salesOrderId: 'so-1',
          documentType: InvoiceDocumentType.xml,
          idempotencyKey: 'doc-xml-1',
        ),
      );
      expect(request.operationId, isNotEmpty);
      expect(request.status, InvoiceDocumentStatus.pending);
      expect(request.downloadUrl, isNull);

      final documents = await module.executeQueryAsync(
        GetInvoiceDocumentsQuery(
          tenantId: 't1',
          actorId: 'a1',
          salesOrderId: 'so-1',
        ),
      );
      expect(documents.xml?.operationId, request.operationId);
      expect(documents.xml?.status, InvoiceDocumentStatus.available);
      expect(documents.xml?.downloadUrl, isNotEmpty);
      expect(documents.xml?.checksum, isNotEmpty);
    });

    test('documents_list_partial exposes typed pdf/xml items', () async {
      final module = FakeEInvoiceModule(scenario: FakeEInvoiceScenario.documentsListPartial);
      final documents = await module.executeQueryAsync(
        GetInvoiceDocumentsQuery(
          tenantId: 't1',
          actorId: 'a1',
          salesOrderId: 'so-1',
        ),
      );

      expect(documents.pdfAvailable, isTrue);
      expect(documents.xmlAvailable, isFalse);
      expect(documents.pdf?.status, InvoiceDocumentStatus.available);
      expect(documents.pdf?.operationId, isNotEmpty);
      expect(documents.pdf?.downloadUrl, isNotEmpty);
      expect(documents.xml?.status, InvoiceDocumentStatus.pending);
      expect(documents.xml?.operationId, isNotEmpty);
      expect(documents.xml?.downloadUrl, isNull);
    });

    test('download_unavailable returns failed operation without sync provider call', () async {
      final module = FakeEInvoiceModule(scenario: FakeEInvoiceScenario.downloadUnavailable);
      final result = await module.executeCommandAsync(
        RequestInvoiceDocumentCommand(
          tenantId: 't1',
          actorId: 'a1',
          salesOrderId: 'so-1',
          documentType: InvoiceDocumentType.pdf,
          idempotencyKey: 'doc-1',
        ),
      );
      expect(result.operationId, 'op-doc-failed-1');
      expect(result.status, InvoiceDocumentStatus.failed);
      expect(result.downloadUrl, isNull);
      expect(result.checksum, isNull);
    });
  });
}
