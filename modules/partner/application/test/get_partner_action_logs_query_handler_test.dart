import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

import 'support/partner_handler_fakes.dart';

void main() {
  group('GetPartnerActionLogsQueryHandler', () {
    test('delegates to read gateway', () async {
      final gateway = RecordingPartnerReadGateway()
        ..actionLogsResult = PartnerActionLogResultDto(
          items: [
            PartnerActionLogItemDto(
              actionLogId: 'al-1',
              actionType: PartnerActionType.create,
              actorUserId: '8acac7ec-0000-4000-8000-000000000001',
              createdAt: DateTime.utc(2026, 7, 14, 16, 26),
            ),
          ],
          total: 1,
          page: 1,
          limit: 20,
        );
      final handler = GetPartnerActionLogsQueryHandler(readGateway: gateway);

      final result = await handler.handle(
        GetPartnerActionLogsQuery(tenantId: 't-1', partnerId: 'p-1'),
      );

      expect(result.items, hasLength(1));
      expect(result.items.first.actionType, PartnerActionType.create);
      expect(gateway.lastActionLogs?.partnerId, 'p-1');
    });
  });
}
