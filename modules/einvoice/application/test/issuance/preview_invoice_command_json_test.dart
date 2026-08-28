import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';

void main() {
  group('PreviewInvoiceCommand', () {
    test('round-trips toJson / fromJson and exposes commandType', () {
      final canonicalInvoice = <String, Object?>{
        'refId': 'ref-100',
        'invSeries': '1C25TYY',
        'invDate': '2026-08-01',
        'buyerLegalName': 'Công ty ABC',
        'buyerTaxCode': '0100109106',
        'buyerAddress': 'Hà Nội',
        'totalAmount': 110000,
      };

      final command = PreviewInvoiceCommand(
        id: 'cmd-preview-1',
        tenantId: 'tenant-123',
        salesOrderId: 'order-456',
        previewRequestId: 'req-789',
        orderVersion: 2,
        canonicalInvoice: canonicalInvoice,
      );

      expect(command.commandType, PreviewInvoiceCommand.type);
      expect(command.commandType, 'einvoice.preview_invoice');

      final payload = command.toJson();
      expect(payload.containsKey('id'), isFalse);
      expect(payload['tenant_id'], 'tenant-123');
      expect(payload['sales_order_id'], 'order-456');
      expect(payload['preview_request_id'], 'req-789');
      expect(payload['order_version'], 2);
      expect(payload['canonical_invoice'], canonicalInvoice);

      final restored = PreviewInvoiceCommand.fromJson(
        payload,
        id: 'cmd-preview-1',
      );
      expect(restored.id, 'cmd-preview-1');
      expect(restored.tenantId, command.tenantId);
      expect(restored.salesOrderId, command.salesOrderId);
      expect(restored.previewRequestId, command.previewRequestId);
      expect(restored.orderVersion, command.orderVersion);
      expect(restored.canonicalInvoice, command.canonicalInvoice);
    });
  });
}
