import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_partner_integration_events/integration_events.dart';
import 'package:vet45_sales_integration_events/integration_events.dart';
import 'package:vet45_shared_application/application.dart';

final class _FakeEinvoiceCommandDispatcher implements IEinvoiceCommandDispatcher {
  final List<StartAutoIssuanceCommand> startCalls = [];
  final List<ReevaluateAutoIssuanceCommand> reevaluateCalls = [];

  @override
  Future<TResult> execute<TResult>(ICommand<TResult> command) async {
    switch (command) {
      case StartAutoIssuanceCommand c:
        startCalls.add(c);
        return const AutoIssuanceResultDto(
              started: true,
              skipped: false,
              processId: 'proc-1',
              attemptId: 'att-1',
            )
            as TResult;
      case ReevaluateAutoIssuanceCommand c:
        reevaluateCalls.add(c);
        return AutoIssuanceResultDto(
              started: true,
              skipped: false,
              processId: c.processId,
              attemptId: 'att-1',
            )
            as TResult;
      default:
        throw UnsupportedError('Unsupported command ${command.runtimeType}');
    }
  }
}

final class _FakeAutoIssuanceGateway implements IAutoIssuanceGateway {
  _FakeAutoIssuanceGateway({
    List<OpenAutoIssuanceProcessDto>? openProcesses,
  }) : _openProcesses = openProcesses ?? [];

  final List<OpenAutoIssuanceProcessDto> _openProcesses;
  String? lastTenantId;
  String? lastPartnerId;

  @override
  Future<AutoIssuanceResultDto> start(AutoIssuanceStartRequest request) async {
    throw UnimplementedError();
  }

  @override
  Future<AutoIssuanceResultDto> reevaluate(
    AutoIssuanceReevaluationRequest request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<List<OpenAutoIssuanceProcessDto>> listOpenProcesses({
    required String tenantId,
    required String partnerId,
  }) async {
    lastTenantId = tenantId;
    lastPartnerId = partnerId;
    return _openProcesses;
  }
}

void main() {
  group('SalesOrderFinalizedIntegrationEventHandler', () {
    test('dispatches single StartAutoIssuanceCommand with deterministic keys', () async {
      final dispatcher = _FakeEinvoiceCommandDispatcher();
      final handler = SalesOrderFinalizedIntegrationEventHandler(
        commands: dispatcher,
      );

      final event = SalesOrderFinalizedIntegrationEvent(
        id: 'event-001',
        occurredOn: DateTime.utc(2026, 9, 15, 10, 2, 57),
        tenantId: 'tenant-1',
        salesOrderId: 'order-123',
        sourceVersion: '1',
      );

      await handler.handle(event);

      expect(dispatcher.startCalls, hasLength(1));
      final cmd = dispatcher.startCalls.single;
      expect(cmd.tenantId, 'tenant-1');
      expect(cmd.salesOrderId, 'order-123');
      expect(
        cmd.triggerKey,
        'sales_order_finalized.v1:event-001:order-123:1',
      );
      expect(
        cmd.idempotencyKey,
        AutoIssuanceIdempotencyKey.generate(
          tenantId: 'tenant-1',
          salesOrderId: 'order-123',
          sourceVersion: '1',
        ),
      );
      expect(dispatcher.reevaluateCalls, isEmpty);
    });
  });

  group('PartnerProfileUpdatedIntegrationEventHandler', () {
    test('partner update continues existing open processes without start dispatch', () async {
      final gateway = _FakeAutoIssuanceGateway(
        openProcesses: const [
          OpenAutoIssuanceProcessDto(
            processId: 'process-1',
            salesOrderId: 'order-1',
            partnerId: 'partner-99',
            status: 'PENDING_REEVALUATION',
          ),
          OpenAutoIssuanceProcessDto(
            processId: 'process-2',
            salesOrderId: 'order-2',
            partnerId: 'partner-99',
            status: 'PENDING_REEVALUATION',
          ),
        ],
      );
      final dispatcher = _FakeEinvoiceCommandDispatcher();
      final handler = PartnerProfileUpdatedIntegrationEventHandler(
        gateway: gateway,
        commands: dispatcher,
      );

      final event = PartnerProfileUpdatedIntegrationEvent(
        id: 'partner-evt-001',
        occurredOn: DateTime.utc(2026, 8, 29, 10, 5, 0),
        tenantId: 'tenant-1',
        partnerId: 'partner-99',
      );

      await handler.handle(event);

      expect(gateway.lastTenantId, 'tenant-1');
      expect(gateway.lastPartnerId, 'partner-99');
      expect(dispatcher.startCalls, isEmpty);
      expect(dispatcher.reevaluateCalls, hasLength(2));
      expect(dispatcher.reevaluateCalls[0].processId, 'process-1');
      expect(dispatcher.reevaluateCalls[0].sourceEventId, 'partner-evt-001');
      expect(dispatcher.reevaluateCalls[0].tenantId, 'tenant-1');
      expect(dispatcher.reevaluateCalls[1].processId, 'process-2');
      expect(dispatcher.reevaluateCalls[1].sourceEventId, 'partner-evt-001');
      expect(dispatcher.reevaluateCalls[1].tenantId, 'tenant-1');
    });

    test('partner update does nothing when no open processes exist', () async {
      final gateway = _FakeAutoIssuanceGateway(openProcesses: const []);
      final dispatcher = _FakeEinvoiceCommandDispatcher();
      final handler = PartnerProfileUpdatedIntegrationEventHandler(
        gateway: gateway,
        commands: dispatcher,
      );

      final event = PartnerProfileUpdatedIntegrationEvent(
        id: 'partner-evt-002',
        occurredOn: DateTime.utc(2026, 8, 29, 10, 6, 0),
        tenantId: 'tenant-1',
        partnerId: 'partner-100',
      );

      await handler.handle(event);

      expect(dispatcher.startCalls, isEmpty);
      expect(dispatcher.reevaluateCalls, isEmpty);
    });
  });
}
