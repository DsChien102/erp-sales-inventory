import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_einvoice_domain/domain.dart';

void main() {
  group('EP-04 fake scenarios', () {
    test('send_ok returns PROCESSING delivery', () async {
      final module = FakeEInvoiceModule(scenario: FakeEInvoiceScenario.sendOk);
      final result = await module.executeCommandAsync(
        SendElectronicInvoiceCommand(
          tenantId: 't1',
          actorId: 'a1',
          salesOrderId: 'so-1',
          recipientEmail: 'buyer@test.com',
          idempotencyKey: 'send-1',
        ),
      );
      expect(result.status, DeliveryStatus.processing);
    });

    test('send_sheet_resend uses resend mode', () async {
      final module = FakeEInvoiceModule(scenario: FakeEInvoiceScenario.sendSheetResend);
      final result = await module.executeQueryAsync(
        GetSendInvoiceSheetContextQuery(
          tenantId: 't1',
          actorId: 'a1',
          salesOrderId: 'so-1',
        ),
      );
      expect(result.mode, SendInvoiceSheetMode.resend);
    });

    test('auto_send_not_supported throws DeliveryNotSupportedException', () async {
      final module = FakeEInvoiceModule(scenario: FakeEInvoiceScenario.autoSendNotSupported);
      expect(
        () => module.executeCommandAsync(
          StartAutoDeliveryCommand(
            tenantId: 't1',
            electronicInvoiceId: 'ei-1',
            triggerId: 'tr-1',
            idempotencyKey: 'auto-1',
          ),
        ),
        throwsA(isA<DeliveryNotSupportedException>()),
      );
    });
  });
}
