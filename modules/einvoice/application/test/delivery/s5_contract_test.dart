import 'dart:io';

import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';

String _librarySource(String relativeToLib) {
  final inPackage = File('lib/$relativeToLib');
  final fromRoot = File('modules/einvoice/application/lib/$relativeToLib');
  final file = inPackage.existsSync() ? inPackage : fromRoot;
  expect(file.existsSync(), isTrue, reason: 'missing lib/$relativeToLib');
  return file.readAsStringSync();
}

void main() {
  group('frozen S5 delivery vocabulary', () {
    test('business and technical status enums are unchanged', () {
      expect(DeliveryStatus.values, <DeliveryStatus>[
        DeliveryStatus.processing,
        DeliveryStatus.succeeded,
        DeliveryStatus.failed,
        DeliveryStatus.unknown,
      ]);
      expect(DeliveryAttemptStatus.values, <DeliveryAttemptStatus>[
        DeliveryAttemptStatus.queued,
        DeliveryAttemptStatus.submitted,
        DeliveryAttemptStatus.succeeded,
        DeliveryAttemptStatus.failed,
        DeliveryAttemptStatus.unknown,
      ]);
      expect(DeliveryKind.values, <DeliveryKind>[
        DeliveryKind.initial,
        DeliveryKind.resend,
      ]);
      expect(DeliveryDisplayState.values, <DeliveryDisplayState>[
        DeliveryDisplayState.notSent,
        DeliveryDisplayState.sending,
        DeliveryDisplayState.sent,
        DeliveryDisplayState.failed,
      ]);
    });

    test('trigger and actor provenance enums are frozen', () {
      expect(DeliveryTriggerType.values, <DeliveryTriggerType>[
        DeliveryTriggerType.automatic,
        DeliveryTriggerType.manual,
      ]);
      expect(DeliveryActorType.values, <DeliveryActorType>[
        DeliveryActorType.system,
        DeliveryActorType.user,
      ]);
    });

    test('recipient resolution sources are frozen and ordered', () {
      expect(DeliveryRecipientSource.values, <DeliveryRecipientSource>[
        DeliveryRecipientSource.currentPartnerProfile,
        DeliveryRecipientSource.buyerInvoiceSnapshot,
        DeliveryRecipientSource.lastSuccessfulPartnerDelivery,
        DeliveryRecipientSource.lastInvoiceDelivery,
        DeliveryRecipientSource.userInput,
      ]);
    });

    test('provider result evidence kinds are exhaustive and typed', () {
      expect(DeliveryResultKind.values, <DeliveryResultKind>[
        DeliveryResultKind.success,
        DeliveryResultKind.definiteFailure,
        DeliveryResultKind.retryableFailure,
        DeliveryResultKind.undetermined,
      ]);
    });
  });

  group('SendElectronicInvoiceCommand', () {
    test('accepts only tenant, actor, order, recipient and idempotency key', () {
      final command = SendElectronicInvoiceCommand(
        tenantId: 't1',
        actorId: 'a1',
        salesOrderId: 'so-1',
        recipientEmail: 'buyer@test.com',
        idempotencyKey: 'send-1',
      );

      expect(command.tenantId, 't1');
      expect(command.actorId, 'a1');
      expect(command.salesOrderId, 'so-1');
      expect(command.recipientEmail, 'buyer@test.com');
      expect(command.idempotencyKey, 'send-1');
    });

    test('never lets the client choose initial versus resend', () {
      final source = _librarySource(
        'src/delivery/commands/send_electronic_invoice/'
        'send_electronic_invoice_command.dart',
      );
      expect(source, isNot(contains('deliveryKind')));
      expect(source, isNot(contains('DeliveryKind')));
    });
  });

  group('RecordDeliveryResultCommand', () {
    test('carries expected versions, interaction reference and evidence', () {
      final command = RecordDeliveryResultCommand(
        tenantId: 't1',
        deliveryId: 'del-1',
        attemptId: 'att-1',
        expectedDeliveryVersion: 3,
        expectedAttemptVersion: 2,
        interactionReference: 'pi-del-1-att-1',
        evidence: const DeliveryResultEvidence(
          kind: DeliveryResultKind.undetermined,
          safeCode: 'PROVIDER_TIMEOUT',
        ),
      );

      expect(command.expectedDeliveryVersion, 3);
      expect(command.expectedAttemptVersion, 2);
      expect(command.interactionReference, 'pi-del-1-att-1');
      expect(command.evidence.kind, DeliveryResultKind.undetermined);
      expect(command.evidence.safeCode, 'PROVIDER_TIMEOUT');
      expect(command.evidence.providerReference, isNull);
    });

    test('never accepts raw provider payload', () {
      final source = _librarySource(
        'src/delivery/commands/record_delivery_result/'
        'record_delivery_result_command.dart',
      );
      expect(source, isNot(contains('providerResult')));
      expect(source, isNot(contains('Map<String, Object?>')));
    });
  });

  group('public delivery read contracts', () {
    test('RecordDeliveryResultDto exposes secondary attention', () {
      const dto = RecordDeliveryResultDto(
        deliveryStatus: DeliveryStatus.unknown,
        displayState: DeliveryDisplayState.sent,
        hasSecondaryAttention: true,
      );

      expect(dto.deliveryStatus, DeliveryStatus.unknown);
      expect(dto.displayState, DeliveryDisplayState.sent);
      expect(dto.hasSecondaryAttention, isTrue);
    });

    test('InvoiceDeliveryItemDto exposes immutable business evidence', () {
      final startedAt = DateTime.utc(2026, 9, 2, 10);
      final completedAt = DateTime.utc(2026, 9, 2, 10, 1);
      final item = InvoiceDeliveryItemDto(
        deliveryId: 'del-1',
        deliveryNo: 1,
        kind: DeliveryKind.initial,
        triggerType: DeliveryTriggerType.automatic,
        recipientEmail: 'buyer@test.com',
        status: DeliveryStatus.succeeded,
        initiatedByActorType: DeliveryActorType.system,
        initiatedByActorId: null,
        startedAt: startedAt,
        completedAt: completedAt,
        failureCode: null,
      );

      expect(item.deliveryNo, 1);
      expect(item.kind, DeliveryKind.initial);
      expect(item.triggerType, DeliveryTriggerType.automatic);
      expect(item.initiatedByActorType, DeliveryActorType.system);
      expect(item.initiatedByActorId, isNull);
      expect(item.startedAt, startedAt);
      expect(item.completedAt, completedAt);
      expect(item.failureCode, isNull);
    });

    test('InvoiceDeliveryHistoryDto separates display state from attention', () {
      const history = InvoiceDeliveryHistoryDto(
        deliveries: <InvoiceDeliveryItemDto>[],
        displayState: DeliveryDisplayState.sent,
        hasSecondaryAttention: true,
      );

      expect(history.displayState, DeliveryDisplayState.sent);
      expect(history.hasSecondaryAttention, isTrue);
    });

    test('SendInvoiceSheetContextDto exposes suggestion source and lock', () {
      const context = SendInvoiceSheetContextDto(
        mode: SendInvoiceSheetMode.resend,
        suggestedEmail: 'buyer@test.com',
        suggestedEmailSource: DeliveryRecipientSource.lastInvoiceDelivery,
        history: <InvoiceDeliveryItemDto>[],
        operationLocked: true,
        displayState: DeliveryDisplayState.sending,
      );

      expect(
        context.suggestedEmailSource,
        DeliveryRecipientSource.lastInvoiceDelivery,
      );
      expect(context.operationLocked, isTrue);
      expect(context.displayState, DeliveryDisplayState.sending);
    });
  });
}
