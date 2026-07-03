import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

class _RecordingWriteGateway implements IPartnerTransactionHistoryWriteGateway {
  RecordPartnerTransactionHistoryCommand? lastCommand;

  @override
  Future<void> upsert(RecordPartnerTransactionHistoryCommand command) async {
    lastCommand = command;
  }
}

void main() {
  test('RecordPartnerTransactionHistoryCommandHandler upserts projection', () async {
    final gateway = _RecordingWriteGateway();
    final handler = RecordPartnerTransactionHistoryCommandHandler(
      writeGateway: gateway,
    );

    await handler.handle(
      RecordPartnerTransactionHistoryCommand(
        tenantId: 'tenant-1',
        businessPartnerId: 'partner-1',
        transactionRole: PartnerRole.customer,
        sourceModule: 'sales',
        sourceType: 'order',
        sourceId: 'order-1',
        sourceCode: 'SO-001',
        transactionDate: DateTime.parse('2026-06-30T10:00:00Z'),
        amount: 1000,
        status: 'completed',
        description: 'Ban hang',
      ),
    );

    expect(gateway.lastCommand?.sourceId, 'order-1');
    expect(gateway.lastCommand?.transactionRole, PartnerRole.customer);
  });
}
