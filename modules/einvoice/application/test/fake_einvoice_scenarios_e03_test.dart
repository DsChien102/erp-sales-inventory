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

    test('download_pdf_ok returns download URL', () async {
      final module = FakeEInvoiceModule(scenario: FakeEInvoiceScenario.downloadPdfOk);
      final result = await module.executeCommandAsync(
        RequestInvoiceDocumentCommand(
          tenantId: 't1',
          actorId: 'a1',
          salesOrderId: 'so-1',
          documentType: InvoiceDocumentType.pdf,
          idempotencyKey: 'doc-1',
        ),
      );
      expect(result.downloadUrl, contains('pdf'));
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
    });
  });
}
