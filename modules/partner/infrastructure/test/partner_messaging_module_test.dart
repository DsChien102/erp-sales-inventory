import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_infrastructure/infrastructure.dart';
import 'package:vet45_partner_integration_events/integration_events.dart';

final class _ConfigurableRpc implements PartnerSchemaRpc {
  _ConfigurableRpc({
    this.inboxRows = const [],
    this.internalRows = const [],
  });

  final List<Map<String, dynamic>> inboxRows;
  final List<Map<String, dynamic>> internalRows;

  @override
  Future<List<Map<String, dynamic>>> callList(
    String functionName, {
    Map<String, dynamic>? params,
  }) async {
    return switch (functionName) {
      'claim_inbox_batch' => inboxRows,
      'claim_internal_commands_batch' => internalRows,
      _ => const [],
    };
  }

  @override
  Future<T> callScalar<T>(
    String functionName, {
    Map<String, dynamic>? params,
  }) async {
    return null as T;
  }
}

final class _NoopWriteGateway implements IPartnerTransactionHistoryWriteGateway {
  @override
  Future<void> upsert(RecordPartnerTransactionHistoryCommand command) async {}
}

PartnerMessagingModule _module({
  List<Map<String, dynamic>> inboxRows = const [],
  List<Map<String, dynamic>> internalRows = const [],
}) {
  final rpc = _ConfigurableRpc(
    inboxRows: inboxRows,
    internalRows: internalRows,
  );
  final recordHandler = RecordPartnerTransactionHistoryCommandHandler(
    writeGateway: _NoopWriteGateway(),
  );

  return PartnerMessagingModule(
    inboxProcessor: PartnerInboxProcessor(
      rpcClient: rpc,
      ingestor: PartnerTransactionHistoryIngestor(recordHandler: recordHandler),
    ),
    internalCommandProcessor: PartnerInternalCommandProcessor(
      rpcClient: rpc,
      recordHandler: recordHandler,
    ),
  );
}

void main() {
  test('exposes partner module name', () {
    expect(_module().name, 'partner');
  });

  test('returns empty result when both queues are idle', () async {
    final result = await _module().processMessagingOnce(tenantId: 'tenant-1');

    expect(result.hadInboxWork, isFalse);
    expect(result.hadInternalWork, isFalse);
    expect(result.hadAnyWork, isFalse);
  });

  test('merges inbox and internal work flags', () async {
    final module = _module(
      inboxRows: [
        {
          'message_id': 'event-1',
          'claim_token': 'claim-1',
          'event_type': SalesOrderCheckedOutIntegrationEvent.type,
          'payload': {
            'tenant_id': 'tenant-1',
            'business_partner_id': 'partner-1',
            'order_id': 'order-1',
          },
          'occurred_at': '2026-06-30T12:00:00Z',
        },
      ],
    );

    final result = await module.processMessagingOnce(tenantId: 'tenant-1');

    expect(result.hadInboxWork, isTrue);
    expect(result.hadInternalWork, isFalse);
  });

  test('reports internal work when inbox is idle', () async {
    final module = _module(
      internalRows: [
        {
          'command_id': 'cmd-1',
          'claim_token': 'claim-1',
          'command_type': RecordPartnerTransactionHistoryCommand.commandType,
          'payload': {
            'tenant_id': 'tenant-1',
            'business_partner_id': 'partner-1',
            'transaction_role': 'customer',
            'source_module': 'sales',
            'source_type': 'order',
            'source_id': 'order-1',
            'transaction_date': '2026-06-30T11:00:00Z',
          },
        },
      ],
    );

    final result = await module.processMessagingOnce(tenantId: 'tenant-1');

    expect(result.hadInboxWork, isFalse);
    expect(result.hadInternalWork, isTrue);
  });
}
