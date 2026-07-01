import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_infrastructure/infrastructure.dart';
import 'package:vet45_partner_integration_events/integration_events.dart';

class _RecordingWriteGateway implements IPartnerTransactionHistoryWriteGateway {
  RecordPartnerTransactionHistoryCommand? lastCommand;

  @override
  Future<void> upsert(RecordPartnerTransactionHistoryCommand command) async {
    lastCommand = command;
  }
}

void main() {
  test('ingests sales.order.checked_out into customer projection', () async {
    final gateway = _RecordingWriteGateway();
    final ingestor = PartnerTransactionHistoryIngestor(
      recordHandler: RecordPartnerTransactionHistoryCommandHandler(
        writeGateway: gateway,
      ),
    );

    await ingestor.ingest(
      eventType: SalesOrderCheckedOutIntegrationEvent.type,
      messageId: 'event-1',
      occurredOn: DateTime.parse('2026-06-30T12:00:00Z'),
      payload: {
        'tenant_id': 'tenant-1',
        'business_partner_id': 'partner-1',
        'order_id': 'order-1',
        'order_code': 'SO-001',
        'amount': 500000,
        'status': 'completed',
        'description': 'Don ban hang',
        'transaction_date': '2026-06-30T11:00:00Z',
      },
    );

    expect(gateway.lastCommand?.tenantId, 'tenant-1');
    expect(gateway.lastCommand?.businessPartnerId, 'partner-1');
    expect(gateway.lastCommand?.sourceModule, 'sales');
    expect(gateway.lastCommand?.sourceType, 'order');
    expect(gateway.lastCommand?.transactionRole, PartnerRole.customer);
    expect(gateway.lastCommand?.sourceCode, 'SO-001');
  });
}
