import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../commands_executor.dart';
import 'i_partner_internal_command_client.dart';
import 'partner_internal_command_claim_scope.dart';
import 'process_internal_commands_command.dart';

/// Claims durable internal commands and re-executes them through the
/// `CommandBus` pipeline (never calling handlers directly).
final class ProcessInternalCommandsCommandHandler
    implements ICommandHandler<ProcessInternalCommandsCommand, bool> {
  ProcessInternalCommandsCommandHandler({
    required IPartnerInternalCommandClient commandClient,
    required InternalCommandSerializer serializer,
    ILogger? logger,
  })  : _commandClient = commandClient,
        _serializer = serializer,
        _logger = logger;

  final IPartnerInternalCommandClient _commandClient;
  final InternalCommandSerializer _serializer;
  final ILogger? _logger;

  @override
  Future<bool> handle(ProcessInternalCommandsCommand command) async {
    final rows = await _commandClient.claimBatch(
      tenantId: command.tenantId,
      batchSize: command.batchSize,
    );
    if (rows.isEmpty) {
      _logger?.fine('Internal commands idle tenant=${command.tenantId}');
      return false;
    }

    _logger?.info(
      'Processing internal commands tenant=${command.tenantId} '
      'count=${rows.length}',
    );

    for (final row in rows) {
      final InternalCommandBase<void> internalCommand;
      try {
        internalCommand =
            _serializer.deserializeRow(_rowToMap(row)) as InternalCommandBase<void>;
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
        await PartnerInternalCommandClaimScope.run(
          PartnerInternalCommandClaim(
            tenantId: command.tenantId,
            claimToken: row.claimToken,
          ),
          () => CommandsExecutor.execute(internalCommand),
        );
        _logger?.info(
          'Internal command complete tenant=${command.tenantId} '
          'commandId=${row.commandId} type=${row.commandType}',
        );
      } catch (error, stackTrace) {
        _logger?.severe(
          'Internal command failed tenant=${command.tenantId} '
          'commandId=${row.commandId} type=${row.commandType}',
          error,
          stackTrace,
        );
        rethrow;
      }
    }

    return true;
  }

  Map<String, dynamic> _rowToMap(PartnerInternalCommandRow row) => {
        'command_id': row.commandId,
        'command_type': row.commandType,
        'payload': row.payload,
      };
}
