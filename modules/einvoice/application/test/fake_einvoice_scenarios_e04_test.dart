import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_einvoice_domain/domain.dart';

void main() {
  group('EP-04 fake scenarios', () {
    test('scn_e04_u01_fr01_01 auto send started', () async {
      final module = FakeEInvoiceModule(scenario: FakeEInvoiceScenario.autoSendStarted);
      final result = await module.executeCommandAsync(
        StartAutoDeliveryCommand(
          tenantId: 't1',
          electronicInvoiceId: 'ei-1',
          triggerId: 'tr-1',
          idempotencyKey: AutoDeliveryIdempotencyKey.generate(
            tenantId: 't1',
            electronicInvoiceId: 'ei-1',
          ),
        ),
      );
      expect(result.disposition, AutoDeliveryDisposition.started);
      expect(result.deliveryId, isNotNull);
    });

    test('scn_e04_u02_fr08_01 manual initial send processing', () async {
      final module = FakeEInvoiceModule(scenario: FakeEInvoiceScenario.sendOk);
      final result = await module.executeCommandAsync(
        SendElectronicInvoiceCommand(
          tenantId: 't1',
          actorId: 'a1',
          salesOrderId: 'so-1',
          recipientEmail: 'changed@buyer.test',
          idempotencyKey: 'send-initial-1',
        ),
      );
      expect(result.status, DeliveryStatus.processing);
    });

    test('scn_e04_u03_fr04_01 delivery success projection', () async {
      final module = FakeEInvoiceModule(scenario: FakeEInvoiceScenario.deliverySuccess);
      final result = await module.executeCommandAsync(
        RecordDeliveryResultCommand(
          tenantId: 't1',
          deliveryId: 'del-1',
          attemptId: 'att-1',
          expectedDeliveryVersion: 1,
          expectedAttemptVersion: 1,
          interactionReference: 'ix-1',
          evidence: const DeliveryResultEvidence(
            kind: DeliveryResultKind.success,
            providerReference: 'prov-1',
          ),
        ),
      );
      expect(result.deliveryStatus, DeliveryStatus.succeeded);
      expect(result.displayState, DeliveryDisplayState.sent);
    });

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
