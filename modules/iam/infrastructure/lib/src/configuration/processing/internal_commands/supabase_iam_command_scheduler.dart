import 'package:vet45_adapters/vet45_adapters.dart'
    hide InternalCommandSerializer, ISerializableInternalCommand;
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../../errors/iam_error_mapper.dart';

/// Enqueues durable internal commands via `iam.enqueue_internal_command`.
final class SupabaseIamCommandScheduler implements ICommandScheduler {
  SupabaseIamCommandScheduler({
    required SupabaseSchemaRpcClient rpcClient,
    required InternalCommandSerializer serializer,
  }) : _rpcClient = rpcClient,
       _serializer = serializer;

  final SupabaseSchemaRpcClient _rpcClient;
  final InternalCommandSerializer _serializer;

  @override
  Future<String> enqueue(
    ICommand<void> command, {
    String? sourceEventId,
  }) async {
    if (command is! ISerializableInternalCommand) {
      throw ArgumentError.value(
        command,
        'command',
        'must implement ISerializableInternalCommand',
      );
    }
    if (command is! CommandBase) {
      throw ArgumentError.value(
        command,
        'command',
        'must extend CommandBase to provide command id',
      );
    }
    final serializable = command as ISerializableInternalCommand;
    final commandId = command.id;
    try {
      final params = <String, dynamic>{
        'p_tenant_id': _serializer.tenantIdOf(serializable),
        'p_command_type': _serializer.commandTypeOf(serializable),
        'p_payload': _serializer.toPayload(serializable),
        'p_command_id': commandId,
      };
      if (sourceEventId != null) {
        params['p_source_event_id'] = sourceEventId;
      }
      final id = await _rpcClient.callScalar<String>(
        'enqueue_internal_command',
        params: params,
      );
      return id ?? commandId;
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }
}
