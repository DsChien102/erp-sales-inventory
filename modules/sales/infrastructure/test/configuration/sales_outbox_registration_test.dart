import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:vet45_sales_infrastructure/infrastructure.dart';
import 'package:vet45_sales_infrastructure/src/configuration/processing/outbox/i_sales_outbox_client.dart';

void main() {
  group('Sales outbox registration', () {
    test('ProcessOutboxCommand is wired through ISalesModule', () async {
      final fakeOutbox = _FakeSalesOutboxClient();
      final module = SalesStartup.initializeForTesting(
        supabase: SupabaseClient('https://example.test', 'anon-key'),
        salesOutboxClient: fakeOutbox,
      );

      final result = await module.executeCommandAsync<bool>(
        ProcessOutboxCommand(tenantId: 'tenant-1', batchSize: 7),
      );

      expect(result, isTrue);
      expect(fakeOutbox.lastTenantId, 'tenant-1');
      expect(fakeOutbox.lastLimit, 7);
    });
  });
}

final class _FakeSalesOutboxClient implements ISalesOutboxClient {
  String? lastTenantId;
  int? lastLimit;

  @override
  Future<List<ClaimedSalesOutboxMessage>> claimBatch({
    required String tenantId,
    required int limit,
  }) async {
    lastTenantId = tenantId;
    lastLimit = limit;
    return [
      ClaimedSalesOutboxMessage(
        messageId: 'event-1',
        eventType: 'sales_order_finalized.v1',
        payload: const {'salesOrderId': 'order-1'},
        occurredAt: DateTime.utc(2026, 9, 15, 10, 2, 57),
        claimToken: 'claim-1',
      ),
    ];
  }

  @override
  Future<void> complete({
    required String tenantId,
    required String messageId,
    required String claimToken,
  }) async {}

  @override
  Future<void> fail({
    required String tenantId,
    required String messageId,
    required String claimToken,
    required String error,
  }) async {}
}
