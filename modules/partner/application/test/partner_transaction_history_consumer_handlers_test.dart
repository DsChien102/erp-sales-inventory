import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_integration_events/integration_events.dart';
import 'package:vet45_shared_application/application.dart';

final class _RecordingScheduler implements ICommandScheduler {
  RecordPartnerTransactionHistoryCommand? last;
  String? lastSourceEventId;

  @override
  Future<String> enqueue(
    ICommand<void> command, {
    String? sourceEventId,
  }) async {
    last = command as RecordPartnerTransactionHistoryCommand;
    lastSourceEventId = sourceEventId;
    return command.id;
  }
}

void main() {
  final occurredOn = DateTime.parse('2026-06-30T12:00:00Z');

  test('sales checkout maps to a customer-role projection command', () async {
    final scheduler = _RecordingScheduler();
    await SalesOrderCheckedOutIntegrationEventHandler(
      commandScheduler: scheduler,
    ).handle(
      SalesOrderCheckedOutIntegrationEvent(
        id: 'event-1',
        occurredOn: occurredOn,
        tenantId: 'tenant-1',
        businessPartnerId: 'partner-1',
        orderId: 'order-1',
        orderCode: 'SO-001',
        amount: 1000,
      ),
    );

    final command = scheduler.last!;
    expect(scheduler.lastSourceEventId, 'event-1');
    expect(command.transactionRole, PartnerRole.customer);
    expect(command.sourceModule, 'sales');
    expect(command.sourceType, 'order');
    expect(command.sourceId, 'order-1');
    expect(command.sourceCode, 'SO-001');
  });

  test('inventory inbound maps to a supplier-role projection command', () async {
    final scheduler = _RecordingScheduler();
    await InventoryInboundRecordedIntegrationEventHandler(
      commandScheduler: scheduler,
    ).handle(
      InventoryInboundRecordedIntegrationEvent(
        id: 'event-2',
        occurredOn: occurredOn,
        tenantId: 'tenant-1',
        businessPartnerId: 'supplier-1',
        inboundId: 'inbound-1',
      ),
    );

    final command = scheduler.last!;
    expect(command.transactionRole, PartnerRole.supplier);
    expect(command.sourceModule, 'inventory');
    expect(command.sourceType, 'inbound');
    expect(command.sourceId, 'inbound-1');
  });

  test('accounting receivable maps to a customer-role projection command', () async {
    final scheduler = _RecordingScheduler();
    await AccountingReceivableCreatedIntegrationEventHandler(
      commandScheduler: scheduler,
    ).handle(
      AccountingReceivableCreatedIntegrationEvent(
        id: 'event-3',
        occurredOn: occurredOn,
        tenantId: 'tenant-1',
        businessPartnerId: 'partner-1',
        receivableId: 'ar-1',
      ),
    );

    final command = scheduler.last!;
    expect(command.transactionRole, PartnerRole.customer);
    expect(command.sourceModule, 'accounting');
    expect(command.sourceType, 'receivable');
    expect(command.sourceId, 'ar-1');
  });

  test('accounting payable maps to a supplier-role projection command', () async {
    final scheduler = _RecordingScheduler();
    await AccountingPayableCreatedIntegrationEventHandler(
      commandScheduler: scheduler,
    ).handle(
      AccountingPayableCreatedIntegrationEvent(
        id: 'event-4',
        occurredOn: occurredOn,
        tenantId: 'tenant-1',
        businessPartnerId: 'supplier-1',
        payableId: 'ap-1',
      ),
    );

    final command = scheduler.last!;
    expect(command.transactionRole, PartnerRole.supplier);
    expect(command.sourceModule, 'accounting');
    expect(command.sourceType, 'payable');
    expect(command.sourceId, 'ap-1');
  });
}
