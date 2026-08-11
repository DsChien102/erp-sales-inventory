import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../commands_executor.dart';
import 'i_iam_internal_command_client.dart';
import 'process_internal_commands_command.dart';

final class ProcessInternalCommandsCommandHandler
    implements ICommandHandler<ProcessInternalCommandsCommand, bool> {
  ProcessInternalCommandsCommandHandler({
    required IIamInternalCommandClient commandClient,
    required InternalCommandSerializer serializer,
  }) : _commandClient = commandClient,
       _serializer = serializer;

  final IIamInternalCommandClient _commandClient;
  final InternalCommandSerializer _serializer;

  @override
  Future<bool> handle(ProcessInternalCommandsCommand command) async {
    final rows = await _commandClient.claimBatch(
      tenantId: command.tenantId,
      limit: command.batchSize,
    );
    final hadWork = rows.isNotEmpty;

    for (final row in rows) {
      try {
        final internalCommand =
            _serializer.deserializeRow(row.toSerializerRow()) as ICommand<void>;
        await CommandsExecutor.execute(internalCommand);
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
      }
    }

    return hadWork;
  }
}
