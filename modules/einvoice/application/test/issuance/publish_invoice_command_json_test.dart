import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';

void main() {
  group('PublishInvoiceCommand', () {
    test('round-trips AD-03 fields and exposes commandType', () {
      final canonicalInvoice = <String, Object?>{
        'refId': 'ref-100',
        'invSeries': '1C25TYY',
        'signType': 2,
        'invDate': '2026-08-01',
        'buyerLegalName': 'Công ty ABC',
        'buyerTaxCode': '0100109106',
        'buyerAddress': 'Hà Nội',
        'totalAmount': 110000,
      };

      final command = PublishInvoiceCommand(
        id: 'cmd-publish-1',
        tenantId: 'tenant-123',
        attemptId: 'attempt-456',
        canonicalInvoice: canonicalInvoice,
        payloadHash: 'abc123hash',
        idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
      );

      expect(command.commandType, PublishInvoiceCommand.type);
      expect(command.commandType, 'einvoice.publish_invoice');

      final payload = command.toJson();
      expect(payload.containsKey('id'), isFalse);
      expect(payload.containsKey('correlation'), isFalse);
      expect(payload.containsKey('correlation_id'), isFalse);
      expect(payload.containsKey('invoice_series'), isFalse);
      expect(payload.keys, hasLength(5));
      expect(payload['tenant_id'], 'tenant-123');
      expect(payload['attempt_id'], 'attempt-456');
      expect(payload['canonical_invoice'], canonicalInvoice);
      expect(payload['payload_hash'], 'abc123hash');
      expect(payload['idempotency_key'], '88d18970-380a-4138-bbce-e25049ca9e3c');

      final restored = PublishInvoiceCommand.fromJson(
        payload,
        id: 'cmd-publish-1',
      );
      expect(restored.id, 'cmd-publish-1');
      expect(restored.tenantId, command.tenantId);
      expect(restored.attemptId, command.attemptId);
      expect(restored.canonicalInvoice, command.canonicalInvoice);
      expect(restored.payloadHash, command.payloadHash);
      expect(restored.idempotencyKey, command.idempotencyKey);
    });
  });
}
