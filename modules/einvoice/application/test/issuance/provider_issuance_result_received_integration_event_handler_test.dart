import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_integration_events/integration_events.dart';
import 'package:vet45_shared_application/application.dart';

final class _RecordingCommandDispatcher implements IEinvoiceCommandDispatcher {
  final List<ICommand<dynamic>> executedCommands = [];

  @override
  Future<TResult> execute<TResult>(ICommand<TResult> command) async {
    executedCommands.add(command);
    if (command is RecordIssuanceResultCommand) {
      final recordCommand = command as RecordIssuanceResultCommand;
      final status = switch (recordCommand.evidence) {
        IssuanceSuccessEvidenceDto() => IssuanceAttemptStatus.succeeded,
        IssuanceDefiniteFailureEvidenceDto() => IssuanceAttemptStatus.failed,
        IssuanceUndeterminedEvidenceDto() => IssuanceAttemptStatus.reconciling,
      };
      return RecordIssuanceResultDto(
            attemptStatus: status,
            electronicInvoiceId: recordCommand.evidence is IssuanceSuccessEvidenceDto
                ? 'ei-from-dispatch'
                : null,
          )
          as TResult;
    }
    throw UnsupportedError('Unexpected command: ${command.runtimeType}');
  }
}

void main() {
  const validUuid = '88d18970-380a-4138-bbce-e25049ca9e3c';

  group('ProviderIssuanceResultReceivedIntegrationEventHandler', () {
    test(
      'handles success event and executes RecordIssuanceResultCommand with success evidence',
      () async {
        final dispatcher = _RecordingCommandDispatcher();
        final handler = ProviderIssuanceResultReceivedIntegrationEventHandler(
          commands: dispatcher,
        );

        final event = ProviderIssuanceResultReceivedIntegrationEvent.success(
          id: 'evt-1',
          occurredOn: DateTime.utc(2026, 8, 28, 10, 0),
          tenantId: 'tenant-1',
          attemptId: 'attempt-1',
          correlationId: 'corr-1',
          idempotencyKey: validUuid,
          payloadHash: 'hash-abc',
          providerReference: 'misa-ref-1',
          invoiceNumber: '00000123',
          invoiceSeries: '1C26TVE',
          issuedAt: DateTime.utc(2026, 8, 28, 9, 59),
        );

        await handler.handle(event);

        expect(dispatcher.executedCommands.length, 1);
        final command = dispatcher.executedCommands.first;
        expect(command, isA<RecordIssuanceResultCommand>());
        final recordCommand = command as RecordIssuanceResultCommand;
        expect(recordCommand.tenantId, 'tenant-1');
        expect(recordCommand.attemptId, 'attempt-1');
        expect(recordCommand.correlationId, 'corr-1');
        expect(recordCommand.evidence, isA<IssuanceSuccessEvidenceDto>());
        final evidence = recordCommand.evidence as IssuanceSuccessEvidenceDto;
        expect(evidence.idempotencyKey, validUuid);
        expect(evidence.payloadHash, 'hash-abc');
        expect(evidence.providerReference, 'misa-ref-1');
        expect(evidence.invoiceNumber, '00000123');
        expect(evidence.invoiceSeries, '1C26TVE');
        expect(evidence.issuedAt, DateTime.utc(2026, 8, 28, 9, 59));
      },
    );

    test(
      'handles definiteFailure event and executes RecordIssuanceResultCommand with failure evidence',
      () async {
        final dispatcher = _RecordingCommandDispatcher();
        final handler = ProviderIssuanceResultReceivedIntegrationEventHandler(
          commands: dispatcher,
        );

        final event = ProviderIssuanceResultReceivedIntegrationEvent.definiteFailure(
          id: 'evt-2',
          occurredOn: DateTime.utc(2026, 8, 28, 10, 0),
          tenantId: 'tenant-1',
          attemptId: 'attempt-1',
          correlationId: 'corr-1',
          idempotencyKey: validUuid,
          payloadHash: 'hash-abc',
          providerReference: 'misa-ref-2',
          errorCode: 'ERR_SIGNATURE_INVALID',
          errorMessage: 'Digital certificate expired',
        );

        await handler.handle(event);

        expect(dispatcher.executedCommands.length, 1);
        final command = dispatcher.executedCommands.first;
        expect(command, isA<RecordIssuanceResultCommand>());
        final recordCommand = command as RecordIssuanceResultCommand;
        expect(recordCommand.tenantId, 'tenant-1');
        expect(recordCommand.attemptId, 'attempt-1');
        expect(recordCommand.correlationId, 'corr-1');
        expect(recordCommand.evidence, isA<IssuanceDefiniteFailureEvidenceDto>());
        final evidence = recordCommand.evidence as IssuanceDefiniteFailureEvidenceDto;
        expect(evidence.idempotencyKey, validUuid);
        expect(evidence.payloadHash, 'hash-abc');
        expect(evidence.providerCode, 'ERR_SIGNATURE_INVALID');
        expect(evidence.providerMessage, 'Digital certificate expired');
      },
    );

    test(
      'handles undetermined event and executes RecordIssuanceResultCommand with undetermined evidence',
      () async {
        final dispatcher = _RecordingCommandDispatcher();
        final handler = ProviderIssuanceResultReceivedIntegrationEventHandler(
          commands: dispatcher,
        );

        final event = ProviderIssuanceResultReceivedIntegrationEvent.undetermined(
          id: 'evt-3',
          occurredOn: DateTime.utc(2026, 8, 28, 10, 0),
          tenantId: 'tenant-1',
          attemptId: 'attempt-1',
          correlationId: 'corr-1',
          idempotencyKey: validUuid,
          payloadHash: 'hash-abc',
          providerReference: 'misa-ref-3',
          reasonCode: 'GATEWAY_TIMEOUT',
        );

        await handler.handle(event);

        expect(dispatcher.executedCommands.length, 1);
        final command = dispatcher.executedCommands.first;
        expect(command, isA<RecordIssuanceResultCommand>());
        final recordCommand = command as RecordIssuanceResultCommand;
        expect(recordCommand.tenantId, 'tenant-1');
        expect(recordCommand.attemptId, 'attempt-1');
        expect(recordCommand.correlationId, 'corr-1');
        expect(recordCommand.evidence, isA<IssuanceUndeterminedEvidenceDto>());
        final evidence = recordCommand.evidence as IssuanceUndeterminedEvidenceDto;
        expect(evidence.idempotencyKey, validUuid);
        expect(evidence.payloadHash, 'hash-abc');
        expect(evidence.reasonCode, 'GATEWAY_TIMEOUT');
      },
    );

    test(
      'scn_e02_u04_fr01_02: callback terminal after UNRESOLVED case routes through same command',
      () async {
        final dispatcher = _RecordingCommandDispatcher();
        final handler = ProviderIssuanceResultReceivedIntegrationEventHandler(
          commands: dispatcher,
        );

        // Simulating late terminal callback arrival
        final event = ProviderIssuanceResultReceivedIntegrationEvent.success(
          id: 'evt-late',
          occurredOn: DateTime.utc(2026, 8, 28, 12, 0),
          tenantId: 'tenant-1',
          attemptId: 'attempt-1',
          correlationId: 'corr-unresolved-1',
          idempotencyKey: validUuid,
          payloadHash: 'hash-abc',
          invoiceNumber: '00000999',
          invoiceSeries: '1C26TVE',
          issuedAt: DateTime.utc(2026, 8, 28, 11, 55),
        );

        await handler.handle(event);

        expect(dispatcher.executedCommands.length, 1);
        final recordCommand = dispatcher.executedCommands.first as RecordIssuanceResultCommand;
        expect(recordCommand.correlationId, 'corr-unresolved-1');
        expect(recordCommand.evidence, isA<IssuanceSuccessEvidenceDto>());
        final evidence = recordCommand.evidence as IssuanceSuccessEvidenceDto;
        expect(evidence.providerReference, ''); // null providerReference falls back cleanly
        expect(evidence.invoiceNumber, '00000999');
      },
    );

    test('event serialization/deserialization integrity rejects invalid payload combinations', () {
      expect(
        () => ProviderIssuanceResultReceivedIntegrationEvent.fromPayload({
          'id': 'evt-bad',
          'tenant_id': 'tenant-1',
          'attempt_id': 'attempt-1',
          'correlation_id': 'corr-1',
          'idempotency_key': validUuid,
          'payload_hash': 'hash-1',
          'occurred_on': '2026-08-28T10:00:00Z',
          'outcome': 'unknown_outcome',
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => ProviderIssuanceResultReceivedIntegrationEvent.fromPayload({
          'id': 'evt-bad',
          'tenant_id': 'tenant-1',
          'attempt_id': 'attempt-1',
          'correlation_id': 'corr-1',
          'idempotency_key': validUuid,
          'payload_hash': 'hash-1',
          'occurred_on': '2026-08-28T10:00:00Z',
          'outcome': 'success',
          // missing invoice_number and invoice_series
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
