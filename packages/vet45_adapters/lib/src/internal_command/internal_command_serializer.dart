import 'i_serializable_internal_command.dart';

import 'internal_command_mapper.dart';

typedef InternalCommandDeserializer = ISerializableInternalCommand Function(
  Map<String, dynamic> payload, {
  required String id,
});

class InternalCommandSerializer {
  InternalCommandSerializer({
    required InternalCommandMapper mapper,
    required Map<String, InternalCommandDeserializer> deserializers,
  }) : _mapper = mapper,
       _deserializers = Map.unmodifiable(deserializers);

  final InternalCommandMapper _mapper;
  final Map<String, InternalCommandDeserializer> _deserializers;

  String commandTypeOf(ISerializableInternalCommand command) {
    final mappedType = _mapper.getName(command.runtimeType);
    if (mappedType != null && mappedType != command.commandType) {
      throw StateError(
        'Command type mismatch for ${command.runtimeType}: '
        'expected $mappedType, got ${command.commandType}',
      );
    }
    return command.commandType;
  }

  String tenantIdOf(ISerializableInternalCommand command) => command.tenantId;

  Map<String, dynamic> toPayload(ISerializableInternalCommand command) =>
      command.toJson();

  ISerializableInternalCommand deserialize({
    required String commandType,
    required Map<String, dynamic> payload,
    required String id,
  }) {
    final deserializer = _deserializers[commandType];
    if (deserializer == null) {
      throw StateError('Unknown command type: $commandType');
    }
    return deserializer(payload, id: id);
  }

  ISerializableInternalCommand deserializeRow(Map<String, dynamic> row) {
    return deserialize(
      commandType: row['command_type'] as String,
      payload: Map<String, dynamic>.from(row['payload'] as Map? ?? const {}),
      id: row['id'] as String,
    );
  }
}
