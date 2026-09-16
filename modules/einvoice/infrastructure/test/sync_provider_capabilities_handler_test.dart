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

  @override
  Future<MeInvoicePreviewOutcome> previewUnpublished({
    required String tenantId,
    required Map<String, Object?> canonicalInvoice,
  }) async => throw UnimplementedError();

  @override
  void validateCanonical({required Map<String, Object?> canonicalInvoice}) {}

  @override
  Future<MeInvoiceIssuanceStatusOutcome> getStatus({
    required String tenantId,
    required String statusLookupKey,
    required String invoiceSeries,
    required String idempotencyKey,
    required String payloadHash,
    IssuanceProviderStatusLookup statusLookup =
        IssuanceProviderStatusLookup.providerTransactionId,
  }) => throw UnimplementedError();

  @override
  Future<MeInvoicePublishOutcome> publish({
    required String tenantId,
    required Map<String, Object?> canonicalInvoice,
    required String idempotencyKey,
  }) => throw UnimplementedError();
}

final class _RecordingConnectionGateway
    implements IProviderConnectionCommandGateway {
  RecordConnectionVerifiedCommand? lastVerified;

  @override
  Future<ProviderConnectionResultDto> connect(ConnectProviderCommand command) =>
      throw UnimplementedError();

  @override
  Future<ProviderConnectionCheckResultDto> verify(
    VerifyProviderConnectionCommand command,
  ) => throw UnimplementedError();

  @override
  Future<ProviderConnectionResultDto> reconnect(
    ReconnectProviderCommand command,
  ) => throw UnimplementedError();

  @override
  Future<ProviderConnectionResultDto> disconnect(
    DisconnectProviderCommand command,
  ) => throw UnimplementedError();

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
            templates: [
              ProviderTemplateRef(
                templateId: 'tpl-1',
                name: 'Mẫu 1',
                invoiceSeries: '1C26TAA',
                invoiceWithCode: true,
                isMtt: false,
                isSendSummary: false,
                serial: '1/001',
              ),
              ProviderTemplateRef(
                templateId: 'tpl-2',
                name: 'Mẫu 2',
                invoiceSeries: '1C26TAB',
                invoiceWithCode: true,
                isMtt: false,
                isSendSummary: false,
                serial: '1/002',
              ),
            ],
          ),
        ),
        commandGateway: gateway,
      );

      await handler.handle(
        SyncProviderCapabilitiesCommand(
          tenantId: 'tenant-1',
          connectionId: 'conn-1',
          expectedConnectionVersion: 7,
        ),
      );

      expect(gateway.lastVerified?.status, ProviderConnectionStatus.connected);
      expect(gateway.lastVerified?.expectedConnectionVersion, 7);
      expect(gateway.lastVerified?.capabilities?.templateCount, 2);
      expect(gateway.lastVerified?.capabilities?.templates.length, 2);
      expect(gateway.lastVerified?.capabilities?.templates.first.name, 'Mẫu 1');
      expect(
        gateway.lastVerified?.capabilities?.supportsDeliveryResultObservation,
        isFalse,
      );
      expect(gateway.lastVerified?.capabilities?.supportsPreview, isFalse);
    });

    test('records supportsPreview when MISA advertises it', () async {
      final gateway = _RecordingConnectionGateway();
      final handler = SyncProviderCapabilitiesCommandHandler(
        meInvoiceProviderPort: _FakeMeInvoiceProviderPort(
          const MeInvoiceAuthOutcome.success(
            templateCount: 1,
            supportsEmailDelivery: false,
            supportsPreview: true,
            templates: [],
          ),
        ),
        commandGateway: gateway,
      );

      await handler.handle(
        SyncProviderCapabilitiesCommand(
          tenantId: 'tenant-1',
          connectionId: 'conn-1',
          expectedConnectionVersion: 1,
        ),
      );

      final caps = gateway.lastVerified!.capabilities!;
      expect(caps.supportsPreview, isTrue);
      final json = RecordConnectionVerifiedCommand(
        tenantId: 'tenant-1',
        connectionId: 'conn-1',
        expectedConnectionVersion: 1,
        status: ProviderConnectionStatus.connected,
        capabilities: caps,
      ).toJson();
      final capsJson = json['capabilities'] as Map<String, dynamic>;
      expect(capsJson['supports_preview'], isTrue);

      final restored = RecordConnectionVerifiedCommand.fromJson(
        json,
        id: 'cmd-1',
      );
      expect(restored.capabilities!.supportsPreview, isTrue);
    });

    test(
      'MISA capability sync never advertises delivery-result observation',
      () async {
        final gateway = _RecordingConnectionGateway();
        final handler = SyncProviderCapabilitiesCommandHandler(
          meInvoiceProviderPort: _FakeMeInvoiceProviderPort(
            const MeInvoiceAuthOutcome.success(
              templateCount: 1,
              supportsEmailDelivery: true,
              templates: [],
            ),
          ),
          commandGateway: gateway,
        );

        await handler.handle(
          SyncProviderCapabilitiesCommand(
            tenantId: 'tenant-1',
            connectionId: 'conn-1',
            expectedConnectionVersion: 1,
          ),
        );

        final caps = gateway.lastVerified!.capabilities!;
        expect(caps.supportsDeliveryResultObservation, isFalse);
        final json = RecordConnectionVerifiedCommand(
          tenantId: 'tenant-1',
          connectionId: 'conn-1',
          expectedConnectionVersion: 1,
          status: ProviderConnectionStatus.connected,
          capabilities: caps,
        ).toJson();
        final capsJson = json['capabilities'] as Map<String, dynamic>;
        expect(capsJson['supports_delivery_result_observation'], isFalse);

        final restored = RecordConnectionVerifiedCommand.fromJson(
          json,
          id: 'cmd-1',
        );
        expect(
          restored.capabilities!.supportsDeliveryResultObservation,
          isFalse,
        );
      },
    );
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
          expectedConnectionVersion: 8,
        ),
      );

      expect(
        gateway.lastVerified?.status,
        ProviderConnectionStatus.reconnectRequired,
      );
      expect(gateway.lastVerified?.expectedConnectionVersion, 8);
    });

    test('provider unavailable throws so queue schedules a retry', () async {
      final gateway = _RecordingConnectionGateway();
      final port = _FakeMeInvoiceProviderPort(
        const MeInvoiceAuthOutcome.providerUnavailable(),
      );
      final handler = SyncProviderCapabilitiesCommandHandler(
        meInvoiceProviderPort: port,
        commandGateway: gateway,
      );

      await expectLater(
        handler.handle(
          SyncProviderCapabilitiesCommand(
            tenantId: 'tenant-1',
            connectionId: 'conn-1',
            expectedConnectionVersion: 9,
          ),
        ),
        throwsA(isA<ProviderUnavailableException>()),
      );

      expect(gateway.lastVerified, isNull);
      expect(port.calls, 1);
    });
  });
}
