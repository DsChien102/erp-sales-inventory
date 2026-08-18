import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';

final class _RecordingProviderConnectionCommandGateway
    implements IProviderConnectionCommandGateway {
  ConnectProviderCommand? lastConnect;

  @override
  Future<ProviderConnectionResultDto> connect(
    ConnectProviderCommand command,
  ) async {
    lastConnect = command;
    return const ProviderConnectionResultDto(
      connectionId: 'conn-1',
      status: ProviderConnectionStatus.checkRequired,
    );
  }

  @override
  Future<ProviderConnectionCheckResultDto> verify(
    VerifyProviderConnectionCommand command,
  ) =>
      throw UnimplementedError();

  @override
  Future<ProviderConnectionResultDto> reconnect(
    ReconnectProviderCommand command,
  ) =>
      throw UnimplementedError();

  @override
  Future<ProviderConnectionResultDto> disconnect(
    DisconnectProviderCommand command,
  ) =>
      throw UnimplementedError();

  @override
  Future<ProviderConnectionResultDto> recordConnectionVerified(
    RecordConnectionVerifiedCommand command,
  ) =>
      throw UnimplementedError();
}

void main() {
  // scn_e01_u01_fr01_01
  test('ConnectProviderCommandHandler delegates to gateway', () async {
    final gateway = _RecordingProviderConnectionCommandGateway();
    final handler = ConnectProviderCommandHandler(commandGateway: gateway);

    final result = await handler.handle(
      ConnectProviderCommand(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        username: 'user',
        password: 'secret',
      ),
    );

    expect(result.connectionId, 'conn-1');
    expect(result.status, ProviderConnectionStatus.checkRequired);
    expect(gateway.lastConnect?.username, 'user');
  });
}
