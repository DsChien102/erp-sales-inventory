import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

final class _FakeDispatcher implements IEinvoiceCommandDispatcher {
  final List<RecordDeliveryResultCommand> recordCalls = [];
  bool throwOnRecord = false;
  int? throwOnRecordAttempt;

  @override
  Future<TResult> execute<TResult>(ICommand<TResult> command) async {
    switch (command) {
      case RecordDeliveryResultCommand c:
        recordCalls.add(c);
        final attempt = recordCalls.length;
        if (throwOnRecord || throwOnRecordAttempt == attempt) {
          throw StateError('simulated record delivery result failure');
        }
        return RecordDeliveryResultDto(
              deliveryStatus: switch (c.evidence.kind) {
                DeliveryResultKind.success => DeliveryStatus.succeeded,
                DeliveryResultKind.definiteFailure => DeliveryStatus.failed,
                DeliveryResultKind.retryableFailure => DeliveryStatus.processing,
                DeliveryResultKind.undetermined => DeliveryStatus.unknown,
              },
              displayState: DeliveryDisplayState.sending,
              hasSecondaryAttention: false,
            )
            as TResult;
      default:
        throw UnsupportedError('${command.runtimeType}');
    }
  }
}

DeliveryAttemptContextDto _context() {
  return const DeliveryAttemptContextDto(
    tenantId: 'tenant-1',
    deliveryId: 'del-1',
    attemptId: 'att-1',
    deliveryVersion: 1,
    attemptVersion: 0,
    providerConnectionId: 'conn-1',
    providerTransactionId: 'tx-inv-1',
    invoiceSeries: '1C25TYY',
    recipientEmail: 'buyer@test.com',
    recipientName: 'Buyer',
  );
}

DeliveryProviderContextDto _providerContext() {
  return const DeliveryProviderContextDto(
    tenantId: 'tenant-1',
    providerConnectionId: 'conn-1',
    providerTransactionId: 'tx-inv-1',
    invoiceSeries: '1C25TYY',
    recipientEmail: 'buyer@test.com',
    recipientName: 'Buyer',
  );
}

SendInvoiceEmailCommand _command() {
  return SendInvoiceEmailCommand(
    id: 'att-1',
    tenantId: 'tenant-1',
    deliveryId: 'del-1',
    attemptId: 'att-1',
  );
}

void main() {
  group('SendInvoiceEmailCommand', () {
    test('serializes only tenant, delivery and attempt ids', () {
      final command = _command();
      final json = command.toJson();

      expect(command.commandType, 'einvoice.send_invoice_email');
      expect(json.keys.toSet(), {
        'tenant_id',
        'delivery_id',
        'attempt_id',
      });
      expect(json, isNot(contains('recipient_email')));
      expect(json, isNot(contains('password')));
      expect(json, isNot(contains('access_token')));
    });

    test('round-trips through fromJson without credentials', () {
      final original = _command();
      final restored = SendInvoiceEmailCommand.fromJson(
        original.toJson(),
        id: original.id,
      );

      expect(restored.tenantId, original.tenantId);
      expect(restored.deliveryId, original.deliveryId);
      expect(restored.attemptId, original.attemptId);
      expect(restored.id, original.id);
    });
  });

  group('SendInvoiceEmailCommandHandler prepare branches', () {
    test('skip never calls provider or records result', () async {
      final gateway = FakeDeliveryCommandGateway()
        ..attemptContext = _context()
        ..prepareResult = const PrepareDeliverySkip();
      final provider = FakeInvoiceDeliveryProviderPort();
      final interactions = FakeProviderInteractionGateway();
      final dispatcher = _FakeDispatcher();

      await SendInvoiceEmailCommandHandler(
        commandGateway: gateway,
        providerPort: provider,
        interactionGateway: interactions,
        commandDispatcher: dispatcher,
      ).handle(_command());

      expect(provider.sendCalls, 0);
      expect(interactions.startCalls, isEmpty);
      expect(dispatcher.recordCalls, isEmpty);
    });

    test('recordUnknown records undetermined without HTTP', () async {
      final gateway = FakeDeliveryCommandGateway()
        ..attemptContext = _context()
        ..prepareResult = const PrepareDeliveryRecordUnknown(
          deliveryVersion: 1,
          attemptVersion: 1,
          interactionReference: 'pi-existing',
        );
      final provider = FakeInvoiceDeliveryProviderPort();
      final interactions = FakeProviderInteractionGateway();
      final dispatcher = _FakeDispatcher();

      await SendInvoiceEmailCommandHandler(
        commandGateway: gateway,
        providerPort: provider,
        interactionGateway: interactions,
        commandDispatcher: dispatcher,
      ).handle(_command());

      expect(provider.sendCalls, 0);
      expect(interactions.startCalls, isEmpty);
      expect(dispatcher.recordCalls, hasLength(1));
      expect(
        dispatcher.recordCalls.single.evidence.kind,
        DeliveryResultKind.undetermined,
      );
      expect(
        dispatcher.recordCalls.single.interactionReference,
        'pi-existing',
      );
    });

    test('callProvider starts interaction, calls provider once, records success', () async {
      final gateway = FakeDeliveryCommandGateway()
        ..attemptContext = _context()
        ..prepareResult = PrepareDeliveryCallProvider(
          providerContext: _providerContext(),
          deliveryVersion: 1,
          attemptVersion: 1,
        );
      final provider = FakeInvoiceDeliveryProviderPort()
        ..outcome = const DeliveryProviderSucceeded(
          providerReference: 'misa-email-1',
        );
      final interactions = FakeProviderInteractionGateway();
      final dispatcher = _FakeDispatcher();

      await SendInvoiceEmailCommandHandler(
        commandGateway: gateway,
        providerPort: provider,
        interactionGateway: interactions,
        commandDispatcher: dispatcher,
      ).handle(_command());

      expect(provider.sendCalls, 1);
      expect(interactions.startCalls, hasLength(1));
      expect(interactions.finalizeCalls, hasLength(1));
      expect(interactions.finalizeCalls.single.outcome, ProviderInteractionOutcome.succeeded);
      expect(dispatcher.recordCalls, hasLength(1));
      expect(
        dispatcher.recordCalls.single.evidence.kind,
        DeliveryResultKind.success,
      );
      expect(
        dispatcher.recordCalls.single.evidence.providerReference,
        'misa-email-1',
      );
      expect(
        dispatcher.recordCalls.single.interactionReference,
        startsWith('int-'),
      );
    });
  });

  group('SendInvoiceEmailCommandHandler provider outcomes', () {
    Future<RecordDeliveryResultCommand> runOutcome(
      DeliveryProviderOutcome outcome,
    ) async {
      final gateway = FakeDeliveryCommandGateway()
        ..attemptContext = _context()
        ..prepareResult = PrepareDeliveryCallProvider(
          providerContext: _providerContext(),
          deliveryVersion: 2,
          attemptVersion: 1,
        );
      final provider = FakeInvoiceDeliveryProviderPort()..outcome = outcome;
      final interactions = FakeProviderInteractionGateway();
      final dispatcher = _FakeDispatcher();

      await SendInvoiceEmailCommandHandler(
        commandGateway: gateway,
        providerPort: provider,
        interactionGateway: interactions,
        commandDispatcher: dispatcher,
      ).handle(_command());

      expect(dispatcher.recordCalls, hasLength(1));
      return dispatcher.recordCalls.single;
    }

    test('maps definite failure evidence', () async {
      final recorded = await runOutcome(
        const DeliveryProviderDefiniteFailure('AUTH_REJECTED'),
      );
      expect(recorded.evidence.kind, DeliveryResultKind.definiteFailure);
      expect(recorded.evidence.safeCode, 'AUTH_REJECTED');
    });

    test('maps retryable failure evidence', () async {
      final recorded = await runOutcome(
        const DeliveryProviderRetryableFailure('HTTP_429'),
      );
      expect(recorded.evidence.kind, DeliveryResultKind.retryableFailure);
      expect(recorded.evidence.safeCode, 'HTTP_429');
    });

    test('maps undetermined evidence', () async {
      final recorded = await runOutcome(
        const DeliveryProviderUndetermined('PROVIDER_TIMEOUT'),
      );
      expect(recorded.evidence.kind, DeliveryResultKind.undetermined);
      expect(recorded.evidence.safeCode, 'PROVIDER_TIMEOUT');
    });

    test('exception after barrier records undetermined and does not rethrow', () async {
      final gateway = FakeDeliveryCommandGateway()
        ..attemptContext = _context()
        ..prepareResult = PrepareDeliveryCallProvider(
          providerContext: _providerContext(),
          deliveryVersion: 1,
          attemptVersion: 1,
        );
      final provider = FakeInvoiceDeliveryProviderPort()..throwOnSend = true;
      final interactions = FakeProviderInteractionGateway();
      final dispatcher = _FakeDispatcher();

      await SendInvoiceEmailCommandHandler(
        commandGateway: gateway,
        providerPort: provider,
        interactionGateway: interactions,
        commandDispatcher: dispatcher,
      ).handle(_command());

      expect(provider.sendCalls, 1);
      expect(dispatcher.recordCalls, hasLength(1));
      expect(
        dispatcher.recordCalls.single.evidence.kind,
        DeliveryResultKind.undetermined,
      );
      expect(interactions.finalizeCalls, hasLength(1));
      expect(
        interactions.finalizeCalls.single.outcome,
        ProviderInteractionOutcome.unavailable,
      );
    });

    test(
      'start throw after callProvider records undetermined without provider call',
      () async {
        final gateway = FakeDeliveryCommandGateway()
          ..attemptContext = _context()
          ..prepareResult = PrepareDeliveryCallProvider(
            providerContext: _providerContext(),
            deliveryVersion: 1,
            attemptVersion: 1,
          );
        final provider = FakeInvoiceDeliveryProviderPort();
        final interactions = FakeProviderInteractionGateway()..throwOnStart = true;
        final dispatcher = _FakeDispatcher();

        await SendInvoiceEmailCommandHandler(
          commandGateway: gateway,
          providerPort: provider,
          interactionGateway: interactions,
          commandDispatcher: dispatcher,
        ).handle(_command());

        expect(provider.sendCalls, 0);
        expect(interactions.startCalls, hasLength(1));
        expect(interactions.finalizeCalls, isEmpty);
        expect(dispatcher.recordCalls, hasLength(1));
        expect(
          dispatcher.recordCalls.single.evidence.kind,
          DeliveryResultKind.undetermined,
        );
        expect(
          dispatcher.recordCalls.single.evidence.safeCode,
          'PROVIDER_TRANSPORT_FAILURE',
        );
      },
    );

    test(
      'record failure after successful finalize does not re-finalize conflictingly',
      () async {
        final gateway = FakeDeliveryCommandGateway()
          ..attemptContext = _context()
          ..prepareResult = PrepareDeliveryCallProvider(
            providerContext: _providerContext(),
            deliveryVersion: 1,
            attemptVersion: 1,
          );
        final provider = FakeInvoiceDeliveryProviderPort()
          ..outcome = const DeliveryProviderSucceeded(
            providerReference: 'misa-email-1',
          );
        final interactions = FakeProviderInteractionGateway();
        final dispatcher = _FakeDispatcher()..throwOnRecordAttempt = 1;

        await SendInvoiceEmailCommandHandler(
          commandGateway: gateway,
          providerPort: provider,
          interactionGateway: interactions,
          commandDispatcher: dispatcher,
        ).handle(_command());

        expect(provider.sendCalls, 1);
        expect(interactions.finalizeCalls, hasLength(1));
        expect(
          interactions.finalizeCalls.single.outcome,
          ProviderInteractionOutcome.succeeded,
        );
        expect(dispatcher.recordCalls, hasLength(2));
        expect(
          dispatcher.recordCalls.first.evidence.kind,
          DeliveryResultKind.success,
        );
        expect(
          dispatcher.recordCalls.last.evidence.kind,
          DeliveryResultKind.undetermined,
        );
      },
    );
  });
}
