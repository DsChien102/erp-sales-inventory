import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

import 'support/partner_handler_fakes.dart';

void main() {
  group('scn_e01_u07_fr01_01 partner history handlers', () {
    test('GetPartnerHistoryQueryHandler delegates to read gateway', () async {
      final gateway = RecordingPartnerReadGateway()
        ..historyResult = PartnerHistoryResultDto(
          items: [
            PartnerHistoryItemDto(
              historyId: 'h-1',
              role: PartnerRoleType.customer,
              transactionType: PartnerTransactionType.salesOrder,
              sourceModule: 'sales',
              sourceId: 'so-1',
              referenceCode: 'SO-001',
              transactionDate: DateTime.utc(2026, 7, 1),
              status: 'completed',
              canOpenSource: true,
            ),
          ],
          total: 1,
          page: 1,
          limit: 20,
        );
      final handler = GetPartnerHistoryQueryHandler(readGateway: gateway);

      final result = await handler.handle(
        GetPartnerHistoryQuery(tenantId: 't-1', partnerId: 'p-1'),
      );

      expect(result.items, hasLength(1));
      expect(gateway.lastHistory?.partnerId, 'p-1');
    });

    test('RecordPartnerHistoryCommandHandler upserts via write gateway', () async {
      final gateway = RecordingPartnerHistoryWriteGateway();
      final handler = RecordPartnerHistoryCommandHandler(
        historyWriteGateway: gateway,
      );

      await handler.handle(
        RecordPartnerHistoryCommand(
          tenantId: 't-1',
          partnerId: 'p-1',
          role: PartnerRoleType.customer,
          transactionType: PartnerTransactionType.salesOrder,
          sourceModule: 'sales',
          sourceId: 'so-1',
          referenceCode: 'SO-001',
          transactionDate: DateTime.utc(2026, 7, 1),
          status: 'completed',
          canOpenSource: true,
        ),
      );

      expect(gateway.lastCommand?.sourceId, 'so-1');
    });
  });
}
