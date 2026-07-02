import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_infrastructure/infrastructure.dart';

final class _FakePartnerSchemaRpc implements PartnerSchemaRpc {
  final List<Map<String, dynamic>> claimCommandRows;
  final List<String> completedCommands = [];
  final List<String> failedCommands = [];

  _FakePartnerSchemaRpc({required this.claimCommandRows});

  @override
  Future<List<Map<String, dynamic>>> callList(
    String functionName, {
    Map<String, dynamic>? params,
  }) async {
    expect(functionName, 'claim_internal_commands_batch');
    return claimCommandRows;
  }

  @override
  Future<T> callScalar<T>(
    String functionName, {
    Map<String, dynamic>? params,
  }) async {
    if (functionName == 'complete_internal_command') {
      completedCommands.add(params!['p_command_id'] as String);
      return null as T;
    }
    if (functionName == 'fail_internal_command') {
      failedCommands.add(params!['p_command_id'] as String);
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
  test('returns false when internal command batch is empty', () async {
    final processor = PartnerInternalCommandProcessor(
      rpcClient: _FakePartnerSchemaRpc(claimCommandRows: const []),
      recordHandler: RecordPartnerTransactionHistoryCommandHandler(
        writeGateway: _RecordingWriteGateway(),
      ),
    );

    final hadWork = await processor.processOnce(tenantId: 'tenant-1');

    expect(hadWork, isFalse);
  });

  test('dispatches record_transaction_history and completes command', () async {
    final gateway = _RecordingWriteGateway();
    final rpc = _FakePartnerSchemaRpc(
      claimCommandRows: [
        {
          'command_id': 'cmd-1',
          'claim_token': 'claim-1',
          'command_type': RecordPartnerTransactionHistoryCommand.commandType,
          'payload': {
            'tenant_id': 'tenant-1',
            'business_partner_id': 'partner-1',
            'transaction_role': PartnerRole.customer.name,
            'source_module': 'sales',
            'source_type': 'order',
            'source_id': 'order-1',
            'source_code': 'SO-001',
            'transaction_date': '2026-06-30T11:00:00Z',
            'amount': 500000,
            'status': 'completed',
            'description': 'Don ban hang',
          },
        },
      ],
    );
    final processor = PartnerInternalCommandProcessor(
      rpcClient: rpc,
      recordHandler: RecordPartnerTransactionHistoryCommandHandler(
        writeGateway: gateway,
      ),
    );

    final hadWork = await processor.processOnce(tenantId: 'tenant-1');

    expect(hadWork, isTrue);
    expect(gateway.lastCommand?.businessPartnerId, 'partner-1');
    expect(gateway.lastCommand?.sourceModule, 'sales');
    expect(rpc.completedCommands, ['cmd-1']);
    expect(rpc.failedCommands, isEmpty);
  });

  test('fails command when dispatch throws', () async {
    final rpc = _FakePartnerSchemaRpc(
      claimCommandRows: [
        {
          'command_id': 'cmd-2',
          'claim_token': 'claim-2',
          'command_type': 'partner.unsupported',
          'payload': <String, dynamic>{},
        },
      ],
    );
    final processor = PartnerInternalCommandProcessor(
      rpcClient: rpc,
      recordHandler: RecordPartnerTransactionHistoryCommandHandler(
        writeGateway: _RecordingWriteGateway(),
      ),
    );

    await expectLater(
      processor.processOnce(tenantId: 'tenant-1'),
      throwsA(isA<UnsupportedError>()),
    );
    expect(rpc.failedCommands, ['cmd-2']);
    expect(rpc.completedCommands, isEmpty);
  });
}
