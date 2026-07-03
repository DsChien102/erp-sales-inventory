import 'package:vet45_partner_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'i_partner_internal_command_client.dart';

/// Persists internal commands to `partner.internal_commands` for durable
/// execution by [ProcessInternalCommandsCommandHandler].
final class SupabasePartnerCommandScheduler implements ICommandScheduler {
  SupabasePartnerCommandScheduler({
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
  Future<String> enqueue(
    ICommand<void> command, {
    String? sourceEventId,
  }) async {
    final serializable = command as ISerializableInternalCommand;
    final commandType = _serializer.commandTypeOf(serializable);
    final tenantId = _serializer.tenantIdOf(serializable);
    final payload = _serializer.toPayload(serializable);

    _logger?.info(
      'Enqueue internal command type=$commandType '
      'id=${command.id} tenant=$tenantId '
      'sourceEventId=$sourceEventId',
    );

    await _commandClient.enqueue(
      tenantId: tenantId,
      commandId: command.id,
      commandType: commandType,
      payload: payload,
      sourceEventId: sourceEventId,
    );
    return command.id;
  }
}
