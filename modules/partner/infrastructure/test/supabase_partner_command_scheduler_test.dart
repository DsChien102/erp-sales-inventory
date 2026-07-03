import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_infrastructure/infrastructure.dart';

final class _RecordingInternalCommandClient implements IPartnerInternalCommandClient {
  String? lastTenantId;
  String? lastCommandId;
  String? lastCommandType;
  Map<String, dynamic>? lastPayload;
  String? lastSourceEventId;

  @override
  Future<void> enqueue({
    required String tenantId,
    required String commandId,
    required String commandType,
    required Map<String, dynamic> payload,
    String? sourceEventId,
  }) async {
    lastTenantId = tenantId;
    lastCommandId = commandId;
    lastCommandType = commandType;
    lastPayload = payload;
    lastSourceEventId = sourceEventId;
  }

  @override
  Future<List<PartnerInternalCommandRow>> claimBatch({
    required String tenantId,
    int batchSize = 10,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> complete({
    required String tenantId,
    required String commandId,
    required String claimToken,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> fail({
    required String tenantId,
    required String commandId,
    required String claimToken,
    required String error,
  }) =>
      throw UnimplementedError();
}

void main() {
  test('enqueues record transaction history command with source event id', () async {
    final client = _RecordingInternalCommandClient();
    final scheduler = SupabasePartnerCommandScheduler(
      commandClient: client,
      serializer: createGeneratedPartnerInternalCommandSerializer(),
    );

    await scheduler.enqueue(
      RecordPartnerTransactionHistoryCommand(
        id: 'cmd-1',
        tenantId: 'tenant-1',
        businessPartnerId: 'partner-1',
        transactionRole: PartnerRole.customer,
        sourceModule: 'sales',
        sourceType: 'order',
        sourceId: 'order-1',
        transactionDate: DateTime.parse('2026-06-30T10:00:00Z'),
      ),
      sourceEventId: 'event-1',
    );

    expect(client.lastTenantId, 'tenant-1');
    expect(client.lastCommandId, 'cmd-1');
    expect(client.lastCommandType, RecordPartnerTransactionHistoryCommand.type);
    expect(client.lastSourceEventId, 'event-1');
    expect(client.lastPayload?['source_id'], 'order-1');
  });
}
