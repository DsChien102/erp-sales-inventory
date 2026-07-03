import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_infrastructure/infrastructure.dart';
import 'package:vet45_shared_application/application.dart';

/// Records commands routed through the module mediator and returns canned
/// had-work flags per recurring command type.
final class _RecordingPartnerModule implements IPartnerModule {
  _RecordingPartnerModule({this.inboxWork = false, this.internalWork = false});

  final bool inboxWork;
  final bool internalWork;
  final List<ICommand<dynamic>> executed = [];

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    executed.add(command);
    if (command is ProcessInboxCommand) {
      return inboxWork as TResult;
    }
    if (command is ProcessInternalCommandsCommand) {
      return internalWork as TResult;
    }
    throw UnsupportedError('Unexpected command: ${command.runtimeType}');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    throw UnimplementedError();
  }
}

void main() {
  test('exposes partner module name', () {
    final module = PartnerMessagingModule(module: _RecordingPartnerModule());
    expect(module.name, 'partner');
  });

  test('routes inbox + internal processing through the module command bus', () async {
    final recording = _RecordingPartnerModule();
    final module = PartnerMessagingModule(module: recording);

    await module.processMessagingOnce(tenantId: 'tenant-1', batchSize: 25);

    expect(recording.executed, hasLength(2));
    final inbox = recording.executed[0] as ProcessInboxCommand;
    final internal = recording.executed[1] as ProcessInternalCommandsCommand;
    expect(inbox.tenantId, 'tenant-1');
    expect(inbox.batchSize, 25);
    expect(internal.tenantId, 'tenant-1');
    expect(internal.batchSize, 25);
  });

  test('returns empty result when both queues are idle', () async {
    final module = PartnerMessagingModule(module: _RecordingPartnerModule());

    final result = await module.processMessagingOnce(tenantId: 'tenant-1');

    expect(result.hadInboxWork, isFalse);
    expect(result.hadInternalWork, isFalse);
    expect(result.hadAnyWork, isFalse);
  });

  test('surfaces inbox + internal work flags from the command results', () async {
    final module = PartnerMessagingModule(
      module: _RecordingPartnerModule(inboxWork: true, internalWork: true),
    );

    final result = await module.processMessagingOnce(tenantId: 'tenant-1');

    expect(result.hadInboxWork, isTrue);
    expect(result.hadInternalWork, isTrue);
  });
}
