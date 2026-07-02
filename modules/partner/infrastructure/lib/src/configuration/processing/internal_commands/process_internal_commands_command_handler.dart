import 'package:vet45_partner_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'i_partner_internal_command_client.dart';
import 'process_internal_commands_command.dart';

/// Claims durable internal commands and re-executes them through the
/// `CommandBus` pipeline (never calling handlers directly).
final class ProcessInternalCommandsCommandHandler
    implements ICommandHandler<ProcessInternalCommandsCommand, bool> {
  ProcessInternalCommandsCommandHandler({
    required IPartnerInternalCommandClient commandClient,
    required CommandBus commandBus,
  })  : _commandClient = commandClient,
        _commandBus = commandBus;

  final IPartnerInternalCommandClient _commandClient;
  final CommandBus _commandBus;

  @override
  Future<bool> handle(ProcessInternalCommandsCommand command) async {
    final rows = await _commandClient.claimBatch(
      tenantId: command.tenantId,
      batchSize: command.batchSize,
    );
    if (rows.isEmpty) {
      return false;
    }

    for (final row in rows) {
      final InternalCommandBase<void> internalCommand;
      try {
        internalCommand = _deserialize(row);
      } catch (error) {
        await _commandClient.fail(
          tenantId: command.tenantId,
          commandId: row.commandId,
          claimToken: row.claimToken,
          error: error.toString(),
        );
        continue;
      }

      try {
        await _commandBus.execute<void>(internalCommand);
        await _commandClient.complete(
          tenantId: command.tenantId,
          commandId: row.commandId,
          claimToken: row.claimToken,
        );
      } catch (error) {
        await _commandClient.fail(
          tenantId: command.tenantId,
          commandId: row.commandId,
          claimToken: row.claimToken,
          error: error.toString(),
        );
        rethrow;
      }
    }

    return true;
  }

  InternalCommandBase<void> _deserialize(PartnerInternalCommandRow row) {
    return switch (row.commandType) {
      RecordPartnerTransactionHistoryCommand.commandType =>
        RecordPartnerTransactionHistoryCommand.fromJson(
          row.payload,
          id: row.commandId,
        ),
      _ => throw UnsupportedError(
          'Unsupported partner internal command: ${row.commandType}',
        ),
    };
  }
}
