import 'package:quiver/collection.dart';
import 'package:test/test.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

final class _TestInternalCommand implements ISerializableInternalCommand {
  _TestInternalCommand({
    required this.id,
    required this.tenantId,
    required this.payload,
  });

  final String id;
  @override
  final String tenantId;
  final Map<String, dynamic> payload;

  static const String type = 'test.internal.command';

  @override
  String get commandType => type;

  @override
  Map<String, dynamic> toJson() => payload;

  factory _TestInternalCommand.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    return _TestInternalCommand(
      id: id,
      tenantId: json['tenant_id'] as String,
      payload: Map<String, dynamic>.from(json),
    );
  }
}

void main() {
  group('InternalCommandSerializer', () {
    late InternalCommandSerializer serializer;

    setUp(() {
      final commandTypes = BiMap<String, Type>()
        ..[_TestInternalCommand.type] = _TestInternalCommand;

      serializer = InternalCommandSerializer(
        mapper: InternalCommandMapper(internalCommandMap: commandTypes),
        deserializers: {
          _TestInternalCommand.type: _TestInternalCommand.fromJson,
        },
      );
    });

    test('round-trips serializable internal command', () {
      final command = _TestInternalCommand(
        id: 'cmd-1',
        tenantId: 'tenant-1',
        payload: {
          'tenant_id': 'tenant-1',
          'value': 'hello',
        },
      );

      final deserialized = serializer.deserialize(
        commandType: serializer.commandTypeOf(command),
        payload: serializer.toPayload(command),
        id: command.id,
      );

      expect(deserialized.commandType, command.commandType);
      expect(deserialized.tenantId, command.tenantId);
      expect(deserialized.toJson(), command.toJson());
    });

    test('throws for unknown command type on deserialize', () {
      expect(
        () => serializer.deserialize(
          commandType: 'unknown.type',
          payload: const {},
          id: 'cmd-2',
        ),
        throwsStateError,
      );
    });

    test('deserializeRow reads command_type and payload from row id key', () {
      final command = serializer.deserializeRow({
        'id': 'cmd-3',
        'command_type': _TestInternalCommand.type,
        'payload': {
          'tenant_id': 'tenant-3',
          'value': 'row',
        },
      });

      expect(command.tenantId, 'tenant-3');
      expect(command.toJson()['value'], 'row');
    });

    test('deserializeRow accepts command_id alias for partner claim rows', () {
      final command = serializer.deserializeRow({
        'command_id': 'cmd-4',
        'command_type': _TestInternalCommand.type,
        'payload': {
          'tenant_id': 'tenant-4',
          'value': 'claim',
        },
      });

      expect(command.tenantId, 'tenant-4');
      expect(command.toJson()['value'], 'claim');
    });
  });
}
