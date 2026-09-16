import 'package:meta/meta.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'package:vet45_einvoice_application/application.dart';

import '../commands_executor.dart';
import 'einvoice_internal_command_attempt_policy.dart';
import 'i_einvoice_internal_command_client.dart';
import 'i_einvoice_internal_command_dead_letter_handler.dart';
import 'process_internal_commands_command.dart';

final class ProcessInternalCommandsCommandHandler
    implements ICommandHandler<ProcessInternalCommandsCommand, bool> {
  ProcessInternalCommandsCommandHandler({
    required IEinvoiceInternalCommandClient commandClient,
    required InternalCommandSerializer serializer,
    Map<String, IEinvoiceInternalCommandDeadLetterHandler> deadLetterHandlers =
        const {},
  }) : _commandClient = commandClient,
       _serializer = serializer,
       _deadLetterHandlers = deadLetterHandlers;

  final IEinvoiceInternalCommandClient _commandClient;
  final InternalCommandSerializer _serializer;
  final Map<String, IEinvoiceInternalCommandDeadLetterHandler>
  _deadLetterHandlers;

  /// Live dead-letter map registered at composition time (tests only).
  @visibleForTesting
  Map<String, IEinvoiceInternalCommandDeadLetterHandler>
  get deadLetterHandlersForTest => Map.unmodifiable(_deadLetterHandlers);

  @override
  Future<bool> handle(ProcessInternalCommandsCommand command) async {
    await _commandClient.seedDueReconciliationCommands(
      tenantId: command.tenantId,
      limit: command.batchSize,
    );
    final rows = await _commandClient.claimBatch(
      tenantId: command.tenantId,
      limit: command.batchSize,
    );
    final hadWork = rows.isNotEmpty;

    for (final row in rows) {
      try {
        final payload = Map<String, dynamic>.from(row.payload);
        payload[internalCommandWorkerAttemptNumberKey] = row.retryCount + 1;
        final serializerRow = row.toSerializerRow();
        serializerRow['payload'] = payload;

        final internalCommand =
            _serializer.deserializeRow(serializerRow) as ICommand<void>;
        await EinvoiceCommandsExecutor.execute(internalCommand);
        await _commandClient.complete(
          tenantId: command.tenantId,
          commandId: row.commandId,
          claimToken: row.claimToken,
        );
      } on PublishSeriesLeaseBusyException catch (error) {
        await _commandClient.reschedule(
          tenantId: command.tenantId,
          commandId: row.commandId,
          claimToken: row.claimToken,
          delay: error.retryAfter,
        );
      } catch (error) {
        final attemptNumber = row.retryCount + 1;
        final maxAttempts = maxAttemptsForCommandType(row.commandType);

        if (maxAttempts != null && attemptNumber >= maxAttempts) {
          await _commandClient.fail(
            tenantId: command.tenantId,
            commandId: row.commandId,
            claimToken: row.claimToken,
            error: error.toString(),
          );
          final deadLetterHandler = _deadLetterHandlers[row.commandType];
          if (deadLetterHandler != null) {
            await deadLetterHandler.handleDeadLetter(
              tenantId: command.tenantId,
              command: row,
              error: error,
            );
          }
          continue;
        }

        final disposition = await _commandClient.retryOrDeadLetter(
          tenantId: command.tenantId,
          commandId: row.commandId,
          claimToken: row.claimToken,
          error: error.toString(),
        );

        if (disposition == InternalCommandDisposition.deadLetter) {
          final deadLetterHandler = _deadLetterHandlers[row.commandType];
          if (deadLetterHandler != null) {
            await deadLetterHandler.handleDeadLetter(
              tenantId: command.tenantId,
              command: row,
              error: error,
            );
          }
        }
      }
    }

    return hadWork;
  }
}
