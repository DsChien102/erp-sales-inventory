import 'package:vet45_shared_application/application.dart';

import '../../../electronic_invoice/shared/provider_call_correlation_id.dart';
import '../../../electronic_invoice/shared/provider_interaction_direction.dart';
import '../../../electronic_invoice/shared/provider_interaction_outcome.dart';
import '../../../electronic_invoice/shared/provider_interaction_record.dart';
import '../../../electronic_invoice/shared/provider_interaction_status.dart';
import '../../../ports/i_delivery_command_gateway.dart';
import '../../../ports/i_einvoice_command_dispatcher.dart';
import '../../../ports/i_invoice_delivery_provider_port.dart';
import '../../../ports/i_provider_interaction_gateway.dart';
import '../../shared/delivery_provider_context_dto.dart';
import '../../shared/delivery_provider_outcome.dart';
import '../../shared/delivery_result_evidence.dart';
import '../../shared/delivery_result_kind.dart';
import '../../shared/prepare_delivery_provider_call_result.dart';
import '../record_delivery_result/record_delivery_result_command.dart';
import 'send_invoice_email_command.dart';

@CommandHandlerFor(SendInvoiceEmailCommand)
final class SendInvoiceEmailCommandHandler
    implements ICommandHandler<SendInvoiceEmailCommand, void> {
  SendInvoiceEmailCommandHandler({
    required IDeliveryCommandGateway commandGateway,
    required IInvoiceDeliveryProviderPort providerPort,
    required IProviderInteractionGateway interactionGateway,
    required IEinvoiceCommandDispatcher commandDispatcher,
  }) : _commandGateway = commandGateway,
       _providerPort = providerPort,
       _interactionGateway = interactionGateway,
       _commandDispatcher = commandDispatcher;

  final IDeliveryCommandGateway _commandGateway;
  final IInvoiceDeliveryProviderPort _providerPort;
  final IProviderInteractionGateway _interactionGateway;
  final IEinvoiceCommandDispatcher _commandDispatcher;

  @override
  Future<void> handle(SendInvoiceEmailCommand command) async {
    final context = await _commandGateway.loadAttemptContext(
      tenantId: command.tenantId,
      deliveryId: command.deliveryId,
      attemptId: command.attemptId,
    );
    if (context == null) {
      return;
    }

    final requestReference = ProviderCallCorrelationId.forWorkerAttempt(
      commandId: command.id,
      workerAttemptNumber: command.workerAttemptNumber,
    );

    final preparation = await _commandGateway.prepareProviderCall(
      tenantId: command.tenantId,
      deliveryId: command.deliveryId,
      attemptId: command.attemptId,
      expectedDeliveryVersion: context.deliveryVersion,
      expectedAttemptVersion: context.attemptVersion,
      requestReference: requestReference,
    );

    switch (preparation) {
      case PrepareDeliverySkip():
        return;
      case PrepareDeliveryRecordUnknown(
        :final deliveryVersion,
        :final attemptVersion,
        :final interactionReference,
      ):
        await _commandDispatcher.execute(
          RecordDeliveryResultCommand(
            tenantId: command.tenantId,
            deliveryId: command.deliveryId,
            attemptId: command.attemptId,
            expectedDeliveryVersion: deliveryVersion,
            expectedAttemptVersion: attemptVersion,
            interactionReference: interactionReference,
            evidence: const DeliveryResultEvidence(
              kind: DeliveryResultKind.undetermined,
              safeCode: 'DISPATCH_STATE_UNCERTAIN',
            ),
          ),
        );
        return;
      case PrepareDeliveryCallProvider(
        :final providerContext,
        :final deliveryVersion,
        :final attemptVersion,
      ):
        await _callProvider(
          command: command,
          providerContext: providerContext,
          deliveryVersion: deliveryVersion,
          attemptVersion: attemptVersion,
          requestReference: requestReference,
        );
    }
  }

  Future<void> _callProvider({
    required SendInvoiceEmailCommand command,
    required DeliveryProviderContextDto providerContext,
    required int deliveryVersion,
    required int attemptVersion,
    required String requestReference,
  }) async {
    // After the SUBMITTED dispatch barrier, never generic-retry into another
    // provider HTTP call. Failures from start / transport map to undetermined.
    late final ProviderInteractionRecord interaction;
    try {
      interaction = await _interactionGateway.start(
        tenantId: command.tenantId,
        providerConnectionId: providerContext.providerConnectionId,
        direction: ProviderInteractionDirection.outbound,
        operationType: SendInvoiceEmailCommand.type,
        targetType: 'DELIVERY_ATTEMPT',
        targetId: command.attemptId,
        correlationId: requestReference,
        requestReference: requestReference,
      );
    } catch (_) {
      await _recordUndetermined(
        command: command,
        deliveryVersion: deliveryVersion,
        attemptVersion: attemptVersion,
        interactionReference: requestReference,
      );
      return;
    }

    if (interaction.status == ProviderInteractionStatus.completed) {
      return;
    }

    late final DeliveryProviderOutcome outcome;
    try {
      outcome = await _providerPort.sendEmail(providerContext);
    } catch (_) {
      await _finalizeUnavailableAndRecordUndetermined(
        command: command,
        interactionReference: interaction.interactionReference,
        interactionVersion: interaction.version,
        deliveryVersion: deliveryVersion,
        attemptVersion: attemptVersion,
      );
      return;
    }

    await _finalizeAndRecord(
      command: command,
      interactionReference: interaction.interactionReference,
      interactionVersion: interaction.version,
      deliveryVersion: deliveryVersion,
      attemptVersion: attemptVersion,
      outcome: outcome,
    );
  }

  Future<void> _finalizeAndRecord({
    required SendInvoiceEmailCommand command,
    required String interactionReference,
    required int interactionVersion,
    required int deliveryVersion,
    required int attemptVersion,
    required DeliveryProviderOutcome outcome,
  }) async {
    final evidence = switch (outcome) {
      DeliveryProviderSucceeded(:final providerReference) => DeliveryResultEvidence(
        kind: DeliveryResultKind.success,
        providerReference: providerReference,
      ),
      DeliveryProviderDefiniteFailure(:final safeErrorCode) => DeliveryResultEvidence(
        kind: DeliveryResultKind.definiteFailure,
        safeCode: safeErrorCode,
      ),
      DeliveryProviderRetryableFailure(:final safeErrorCode) => DeliveryResultEvidence(
        kind: DeliveryResultKind.retryableFailure,
        safeCode: safeErrorCode,
      ),
      DeliveryProviderUndetermined(:final safeErrorCode) => DeliveryResultEvidence(
        kind: DeliveryResultKind.undetermined,
        safeCode: safeErrorCode,
      ),
    };

    final interactionOutcome = switch (outcome) {
      DeliveryProviderSucceeded() => ProviderInteractionOutcome.succeeded,
      DeliveryProviderDefiniteFailure() => ProviderInteractionOutcome.definiteFailure,
      DeliveryProviderRetryableFailure() => ProviderInteractionOutcome.definiteFailure,
      DeliveryProviderUndetermined() => ProviderInteractionOutcome.unavailable,
    };

    // Typed provider outcome path: finalize at most once. Never overwrite a
    // successful finalize with unavailable if a later record step fails.
    String resolvedInteractionReference = interactionReference;
    var finalizedSuccessfully = false;
    try {
      final finalized = await _interactionGateway.finalize(
        tenantId: command.tenantId,
        interactionReference: interactionReference,
        expectedVersion: interactionVersion,
        outcome: interactionOutcome,
        providerReference: evidence.providerReference,
        safeErrorCode: evidence.safeCode,
      );
      resolvedInteractionReference = finalized.interactionReference;
      finalizedSuccessfully = true;
    } catch (_) {
      // Leave interaction as-is; still attempt delivery undetermined below.
    }

    try {
      await _commandDispatcher.execute(
        RecordDeliveryResultCommand(
          tenantId: command.tenantId,
          deliveryId: command.deliveryId,
          attemptId: command.attemptId,
          expectedDeliveryVersion: deliveryVersion,
          expectedAttemptVersion: attemptVersion,
          interactionReference: resolvedInteractionReference,
          evidence: evidence,
        ),
      );
    } catch (_) {
      if (finalizedSuccessfully) {
        // Delivery record failed after a typed finalize — map delivery to
        // undetermined without a second conflicting interaction finalize.
        try {
          await _recordUndetermined(
            command: command,
            deliveryVersion: deliveryVersion,
            attemptVersion: attemptVersion,
            interactionReference: resolvedInteractionReference,
          );
        } catch (_) {
          // Do not rethrow into a generic worker retry.
        }
      } else {
        try {
          await _recordUndetermined(
            command: command,
            deliveryVersion: deliveryVersion,
            attemptVersion: attemptVersion,
            interactionReference: interactionReference,
          );
        } catch (_) {
          // Do not rethrow into a generic worker retry.
        }
      }
    }
  }

  Future<void> _finalizeUnavailableAndRecordUndetermined({
    required SendInvoiceEmailCommand command,
    required String interactionReference,
    required int interactionVersion,
    required int deliveryVersion,
    required int attemptVersion,
  }) async {
    try {
      await _interactionGateway.finalize(
        tenantId: command.tenantId,
        interactionReference: interactionReference,
        expectedVersion: interactionVersion,
        outcome: ProviderInteractionOutcome.unavailable,
        safeErrorCode: 'PROVIDER_TRANSPORT_FAILURE',
      );
    } catch (_) {
      // Prefer delivery undetermined even if unavailable finalize fails.
    }
    await _recordUndetermined(
      command: command,
      deliveryVersion: deliveryVersion,
      attemptVersion: attemptVersion,
      interactionReference: interactionReference,
    );
  }

  Future<void> _recordUndetermined({
    required SendInvoiceEmailCommand command,
    required int deliveryVersion,
    required int attemptVersion,
    required String interactionReference,
  }) {
    return _commandDispatcher.execute(
      RecordDeliveryResultCommand(
        tenantId: command.tenantId,
        deliveryId: command.deliveryId,
        attemptId: command.attemptId,
        expectedDeliveryVersion: deliveryVersion,
        expectedAttemptVersion: attemptVersion,
        interactionReference: interactionReference,
        evidence: const DeliveryResultEvidence(
          kind: DeliveryResultKind.undetermined,
          safeCode: 'PROVIDER_TRANSPORT_FAILURE',
        ),
      ),
    );
  }
}
