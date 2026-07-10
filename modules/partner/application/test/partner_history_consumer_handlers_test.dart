import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

import 'support/partner_handler_fakes.dart';

void main() {
  group('partner_history_consumer_handlers', () {
    test('sales order checked out enqueues RecordPartnerHistoryCommand', () async {
      final module = RecordingPartnerModule();
      final handler = SalesOrderCheckedOutHistoryHandler(partnerModule: module);

      await handler.handle(
        tenantId: 't-1',
        partnerId: 'p-1',
        sourceId: 'so-1',
        referenceCode: 'SO-001',
        transactionDate: DateTime.utc(2026, 7, 1),
        status: 'completed',
      );

      expect(module.commands, hasLength(1));
      final command = module.commands.single as RecordPartnerHistoryCommand;
      expect(command.transactionType, PartnerTransactionType.salesOrder);
      expect(command.sourceModule, 'sales');
    });

    test('inventory inbound recorded maps supplier role', () async {
      final module = RecordingPartnerModule();
      final handler = InventoryInboundRecordedHistoryHandler(
        partnerModule: module,
      );

      await handler.handle(
        tenantId: 't-1',
        partnerId: 'p-1',
        sourceId: 'in-1',
        referenceCode: 'IN-001',
        transactionDate: DateTime.utc(2026, 7, 2),
        status: 'posted',
      );

      final command = module.commands.single as RecordPartnerHistoryCommand;
      expect(command.role, PartnerRoleType.supplier);
      expect(command.transactionType, PartnerTransactionType.inventoryInbound);
    });

    test('accounting receivable and payable consumers map modules', () async {
      final module = RecordingPartnerModule();
      await AccountingReceivableCreatedHistoryHandler(partnerModule: module)
          .handle(
        tenantId: 't-1',
        partnerId: 'p-1',
        sourceId: 'ar-1',
        referenceCode: 'AR-001',
        transactionDate: DateTime.utc(2026, 7, 3),
        status: 'open',
      );
      await AccountingPayableCreatedHistoryHandler(partnerModule: module).handle(
        tenantId: 't-1',
        partnerId: 'p-1',
        sourceId: 'ap-1',
        referenceCode: 'AP-001',
        transactionDate: DateTime.utc(2026, 7, 4),
        status: 'open',
      );

      expect(module.commands, hasLength(2));
      expect(
        (module.commands.first as RecordPartnerHistoryCommand).transactionType,
        PartnerTransactionType.accountingReceivable,
      );
      expect(
        (module.commands.last as RecordPartnerHistoryCommand).transactionType,
        PartnerTransactionType.accountingPayable,
      );
    });
  });
}
