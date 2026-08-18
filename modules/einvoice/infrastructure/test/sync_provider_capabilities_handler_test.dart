import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';

final class _FakeMeInvoiceProviderPort implements IMeInvoiceProviderPort {
  _FakeMeInvoiceProviderPort(this.outcome);

  final MeInvoiceAuthOutcome outcome;
  int calls = 0;

  @override
  Future<MeInvoiceAuthOutcome> authenticateAndListTemplates({
    required String tenantId,
    required String connectionId,
  }) async {
    calls++;
    return outcome;
  }
}

final class _RecordingConnectionGateway
    implements IProviderConnectionCommandGateway {
  RecordConnectionVerifiedCommand? lastVerified;

  @override
  Future<ProviderConnectionResultDto> connect(
    ConnectProviderCommand command,
  ) =>
      throw UnimplementedError();

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
  ) async {
    lastVerified = command;
    return ProviderConnectionResultDto(
      connectionId: command.connectionId,
      status: command.status,
    );
  }
}

void main() {
  group('SyncProviderCapabilitiesCommandHandler', () {
    test('records connected on MISA success', () async {
      final gateway = _RecordingConnectionGateway();
      final handler = SyncProviderCapabilitiesCommandHandler(
        meInvoiceProviderPort: _FakeMeInvoiceProviderPort(
          const MeInvoiceAuthOutcome.success(
            templateCount: 2,
            supportsEmailDelivery: true,
          ),
        ),
        commandGateway: gateway,
      );

      await handler.handle(
        SyncProviderCapabilitiesCommand(
          tenantId: 'tenant-1',
          connectionId: 'conn-1',
        ),
      );

      expect(gateway.lastVerified?.status, ProviderConnectionStatus.connected);
      expect(
        gateway.lastVerified?.capabilities?.templateCount,
        2,
      );
    });

    test('soft-fails auth without throwing', () async {
      final gateway = _RecordingConnectionGateway();
      final handler = SyncProviderCapabilitiesCommandHandler(
        meInvoiceProviderPort: _FakeMeInvoiceProviderPort(
          const MeInvoiceAuthOutcome.authFailed(),
        ),
        commandGateway: gateway,
      );

      await handler.handle(
        SyncProviderCapabilitiesCommand(
          tenantId: 'tenant-1',
          connectionId: 'conn-1',
        ),
      );

      expect(
        gateway.lastVerified?.status,
        ProviderConnectionStatus.reconnectRequired,
      );
    });

    test('provider unavailable keeps status unchanged', () async {
      final gateway = _RecordingConnectionGateway();
      final port = _FakeMeInvoiceProviderPort(
        const MeInvoiceAuthOutcome.providerUnavailable(),
      );
      final handler = SyncProviderCapabilitiesCommandHandler(
        meInvoiceProviderPort: port,
        commandGateway: gateway,
      );

      await handler.handle(
        SyncProviderCapabilitiesCommand(
          tenantId: 'tenant-1',
          connectionId: 'conn-1',
        ),
      );

      expect(gateway.lastVerified, isNull);
      expect(port.calls, 1);
    });
  });
}
