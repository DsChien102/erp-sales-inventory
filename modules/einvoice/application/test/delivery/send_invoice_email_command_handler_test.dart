import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

final class _FakeDispatcher implements IEinvoiceCommandDispatcher {
  final List<RecordDeliveryResultCommand> recordCalls = [];
  bool throwOnRecord = false;

  @override
  Future<TResult> execute<TResult>(ICommand<TResult> command) async {
    switch (command) {
      case RecordDeliveryResultCommand c:
        recordCalls.add(c);
        if (throwOnRecord) {
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
    retryCount: 0,
    deliveryVersion: 1,
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
    id: 'cmd-1',
    tenantId: 'tenant-1',
    deliveryId: 'del-1',
    retryCount: 0,
  );
}

SendInvoiceEmailCommandHandler _handler({
  required FakeDeliveryCommandGateway gateway,
  required FakeInvoiceDeliveryProviderPort provider,
  required _FakeDispatcher dispatcher,
}) {
  return SendInvoiceEmailCommandHandler(
    commandGateway: gateway,
    providerPort: provider,
    commandDispatcher: dispatcher,
  );
}

void main() {
  group('SendInvoiceEmailCommand', () {
    test('serializes tenant, delivery and retry count', () {
      final command = _command();
      final json = command.toJson();

      expect(command.commandType, 'einvoice.send_invoice_email');
      expect(json.keys.toSet(), {
        'tenant_id',
        'delivery_id',
        'retry_count',
      });
      expect(json['retry_count'], 0);
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
      expect(restored.retryCount, original.retryCount);
      expect(restored.id, original.id);
    });
  });

  group('SendInvoiceEmailCommandHandler prepare branches', () {
    test('skip never calls provider or records result', () async {
      final gateway = FakeDeliveryCommandGateway()
        ..attemptContext = _context()
        ..prepareResult = const PrepareDeliverySkip();
      final provider = FakeInvoiceDeliveryProviderPort();
      final dispatcher = _FakeDispatcher();

      await _handler(
        gateway: gateway,
        provider: provider,
        dispatcher: dispatcher,
      ).handle(_command());

      expect(provider.sendCalls, 0);
      expect(dispatcher.recordCalls, isEmpty);
    });

    test('recordUnknown records undetermined without HTTP', () async {
      final gateway = FakeDeliveryCommandGateway()
        ..attemptContext = _context()
        ..prepareResult = const PrepareDeliveryRecordUnknown(
          deliveryVersion: 1,
        );
      final provider = FakeInvoiceDeliveryProviderPort();
      final dispatcher = _FakeDispatcher();

      await _handler(
        gateway: gateway,
        provider: provider,
        dispatcher: dispatcher,
      ).handle(_command());

      expect(provider.sendCalls, 0);
      expect(dispatcher.recordCalls, hasLength(1));
      expect(
        dispatcher.recordCalls.single.evidence.kind,
        DeliveryResultKind.undetermined,
      );
      expect(
        dispatcher.recordCalls.single.evidence.safeCode,
        'DISPATCH_STATE_UNCERTAIN',
      );
      expect(
        dispatcher.recordCalls.single.evidence.failureSource,
        FailureSource.internal,
      );
      expect(dispatcher.recordCalls.single.retryCount, 0);
    });

    test('callProvider calls provider once and records success', () async {
      final gateway = FakeDeliveryCommandGateway()
        ..attemptContext = _context()
        ..prepareResult = PrepareDeliveryCallProvider(
          providerContext: _providerContext(),
          deliveryVersion: 1,
        );
      final provider = FakeInvoiceDeliveryProviderPort()
        ..outcome = const DeliveryProviderSucceeded(
          providerReference: 'misa-email-1',
        );
      final dispatcher = _FakeDispatcher();

      await _handler(
        gateway: gateway,
        provider: provider,
        dispatcher: dispatcher,
      ).handle(_command());

      expect(provider.sendCalls, 1);
      expect(dispatcher.recordCalls, hasLength(1));
      expect(
        dispatcher.recordCalls.single.evidence.kind,
        DeliveryResultKind.success,
      );
      expect(
        dispatcher.recordCalls.single.evidence.providerReference,
        'misa-email-1',
      );
      expect(dispatcher.recordCalls.single.evidence.failureSource, isNull);
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
        );
      final provider = FakeInvoiceDeliveryProviderPort()..outcome = outcome;
      final dispatcher = _FakeDispatcher();

      await _handler(
        gateway: gateway,
        provider: provider,
        dispatcher: dispatcher,
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
      expect(recorded.evidence.failureSource, FailureSource.provider);
    });

    test('maps retryable failure evidence', () async {
      final recorded = await runOutcome(
        const DeliveryProviderRetryableFailure('HTTP_429'),
      );
      expect(recorded.evidence.kind, DeliveryResultKind.retryableFailure);
      expect(recorded.evidence.safeCode, 'HTTP_429');
      expect(recorded.evidence.failureSource, FailureSource.provider);
    });

    test('maps undetermined evidence', () async {
      final recorded = await runOutcome(
        const DeliveryProviderUndetermined('PROVIDER_TIMEOUT'),
      );
      expect(recorded.evidence.kind, DeliveryResultKind.undetermined);
      expect(recorded.evidence.safeCode, 'PROVIDER_TIMEOUT');
      expect(recorded.evidence.failureSource, FailureSource.provider);
    });

    test('transport failure records undetermined internal evidence', () async {
      final gateway = FakeDeliveryCommandGateway()
        ..attemptContext = _context()
        ..prepareResult = PrepareDeliveryCallProvider(
          providerContext: _providerContext(),
          deliveryVersion: 1,
        );
      final provider = FakeInvoiceDeliveryProviderPort()..throwOnSend = true;
      final dispatcher = _FakeDispatcher();

      await _handler(
        gateway: gateway,
        provider: provider,
        dispatcher: dispatcher,
      ).handle(_command());

      expect(provider.sendCalls, 1);
      expect(dispatcher.recordCalls, hasLength(1));
      expect(
        dispatcher.recordCalls.single.evidence.kind,
        DeliveryResultKind.undetermined,
      );
      expect(
        dispatcher.recordCalls.single.evidence.safeCode,
        'PROVIDER_TRANSPORT_FAILURE',
      );
      expect(
        dispatcher.recordCalls.single.evidence.failureSource,
        FailureSource.internal,
      );
    });

    test('record failure rethrows and the next run records UNKNOWN', () async {
      final gateway = FakeDeliveryCommandGateway()
        ..attemptContext = _context()
        ..prepareResult = PrepareDeliveryCallProvider(
          providerContext: _providerContext(),
          deliveryVersion: 1,
        );
      final provider = FakeInvoiceDeliveryProviderPort()
        ..outcome = const DeliveryProviderSucceeded(
          providerReference: 'misa-email-1',
        );
      final dispatcher = _FakeDispatcher()..throwOnRecord = true;
      final handler = _handler(
        gateway: gateway,
        provider: provider,
        dispatcher: dispatcher,
      );

      await expectLater(handler.handle(_command()), throwsStateError);
      expect(provider.sendCalls, 1);
      expect(dispatcher.recordCalls, hasLength(1));
      expect(
        dispatcher.recordCalls.single.evidence.kind,
        DeliveryResultKind.success,
      );

      gateway.prepareResult = const PrepareDeliveryRecordUnknown(
        deliveryVersion: 2,
      );
      dispatcher.throwOnRecord = false;
      await handler.handle(_command());

      expect(provider.sendCalls, 1);
      expect(dispatcher.recordCalls, hasLength(2));
      expect(
        dispatcher.recordCalls.last.evidence.kind,
        DeliveryResultKind.undetermined,
      );
      expect(
        dispatcher.recordCalls.last.evidence.safeCode,
        'DISPATCH_STATE_UNCERTAIN',
      );
      expect(dispatcher.recordCalls.last.expectedDeliveryVersion, 2);
    });
  });
}
