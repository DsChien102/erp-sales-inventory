import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_infrastructure/infrastructure.dart';
import 'package:vet45_partner_integration_events/integration_events.dart';

final class _FakePartnerSchemaRpc implements PartnerSchemaRpc {
  final List<Map<String, dynamic>> claimInboxRows;
  final List<String> completedInboxMessages = [];
  final List<String> failedInboxMessages = [];

  _FakePartnerSchemaRpc({required this.claimInboxRows});

  @override
  Future<List<Map<String, dynamic>>> callList(
    String functionName, {
    Map<String, dynamic>? params,
  }) async {
    expect(functionName, 'claim_inbox_batch');
    return claimInboxRows;
  }

  @override
  Future<T> callScalar<T>(
    String functionName, {
    Map<String, dynamic>? params,
  }) async {
    if (functionName == 'complete_inbox_message') {
      completedInboxMessages.add(params!['p_message_id'] as String);
      return null as T;
    }
    if (functionName == 'fail_inbox_message') {
      failedInboxMessages.add(params!['p_message_id'] as String);
      return null as T;
    }
    fail('Unexpected RPC: $functionName');
  }
}

final class _RecordingWriteGateway implements IPartnerTransactionHistoryWriteGateway {
  RecordPartnerTransactionHistoryCommand? lastCommand;

  @override
  Future<void> upsert(RecordPartnerTransactionHistoryCommand command) async {
    lastCommand = command;
  }
}

void main() {
  test('returns false when inbox batch is empty', () async {
    final processor = PartnerInboxProcessor(
      rpcClient: _FakePartnerSchemaRpc(claimInboxRows: const []),
      ingestor: PartnerTransactionHistoryIngestor(
        recordHandler: RecordPartnerTransactionHistoryCommandHandler(
          writeGateway: _RecordingWriteGateway(),
        ),
      ),
    );

    final hadWork = await processor.processOnce(tenantId: 'tenant-1');

    expect(hadWork, isFalse);
  });

  test('claims inbox, ingests event, and completes message', () async {
    final gateway = _RecordingWriteGateway();
    final rpc = _FakePartnerSchemaRpc(
      claimInboxRows: [
        {
          'message_id': 'event-1',
          'claim_token': 'claim-1',
          'event_type': SalesOrderCheckedOutIntegrationEvent.type,
          'payload': {
            'tenant_id': 'tenant-1',
            'business_partner_id': 'partner-1',
            'order_id': 'order-1',
            'order_code': 'SO-001',
          },
          'occurred_at': '2026-06-30T12:00:00Z',
        },
      ],
    );
    final processor = PartnerInboxProcessor(
      rpcClient: rpc,
      ingestor: PartnerTransactionHistoryIngestor(
        recordHandler: RecordPartnerTransactionHistoryCommandHandler(
          writeGateway: gateway,
        ),
      ),
    );

    final hadWork = await processor.processOnce(tenantId: 'tenant-1');

    expect(hadWork, isTrue);
    expect(gateway.lastCommand?.sourceId, 'order-1');
    expect(gateway.lastCommand?.sourceCode, 'SO-001');
    expect(rpc.completedInboxMessages, ['event-1']);
    expect(rpc.failedInboxMessages, isEmpty);
  });

  test('fails inbox message when ingestor throws', () async {
    final rpc = _FakePartnerSchemaRpc(
      claimInboxRows: [
        {
          'message_id': 'event-2',
          'claim_token': 'claim-2',
          'event_type': 'unsupported.event',
          'payload': <String, dynamic>{},
          'occurred_at': '2026-06-30T12:00:00Z',
        },
      ],
    );
    final processor = PartnerInboxProcessor(
      rpcClient: rpc,
      ingestor: PartnerTransactionHistoryIngestor(
        recordHandler: RecordPartnerTransactionHistoryCommandHandler(
          writeGateway: _RecordingWriteGateway(),
        ),
      ),
    );

    await expectLater(
      processor.processOnce(tenantId: 'tenant-1'),
      throwsA(isA<UnsupportedError>()),
    );
    expect(rpc.failedInboxMessages, ['event-2']);
    expect(rpc.completedInboxMessages, isEmpty);
  });
}
