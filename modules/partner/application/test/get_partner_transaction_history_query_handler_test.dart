import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

class _RecordingTransactionHistoryReadGateway
    implements IPartnerTransactionHistoryReadGateway {
  String? lastTenantId;
  String? lastPartnerId;
  PartnerTransactionHistoryCriteria? lastCriteria;
  int? lastLimit;
  int? lastOffset;

  @override
  Future<PartnerTransactionHistoryResultDto> list({
    required String tenantId,
    required String partnerId,
    required PartnerTransactionHistoryCriteria criteria,
    int limit = 100,
    int offset = 0,
  }) async {
    lastTenantId = tenantId;
    lastPartnerId = partnerId;
    lastCriteria = criteria;
    lastLimit = limit;
    lastOffset = offset;

    return PartnerTransactionHistoryResultDto(
      items: [
        PartnerTransactionHistoryItemDto(
          id: 'history-1',
          partnerId: partnerId,
          transactionRole: PartnerRole.customer.name,
          transactionType: 'order',
          occurredAt: DateTime.parse('2026-06-30T10:00:00Z'),
          transactionCode: 'SO-001',
          amount: 150000,
          status: 'completed',
          description: 'Ban hang',
          sourceNavigation: const PartnerTransactionSourceNavigationDto(
            sourceModule: 'sales',
            sourceType: 'order',
            sourceId: 'order-1',
            requiredPermission: 'sales.order.view',
          ),
        ),
      ],
      totalCount: 1,
    );
  }
}

void main() {
  test('GetPartnerTransactionHistoryQueryHandler delegates to read gateway', () async {
    final gateway = _RecordingTransactionHistoryReadGateway();
    final handler = GetPartnerTransactionHistoryQueryHandler(
      readGateway: gateway,
    );
    final criteria = PartnerTransactionHistoryCriteria(
      keyword: '  SO-001  ',
      transactionTypes: {'order'},
      transactionRole: PartnerRole.customer,
    );

    final result = await handler.handle(
      GetPartnerTransactionHistoryQuery(
        tenantId: 'tenant-1',
        partnerId: 'partner-1',
        criteria: criteria,
        limit: 20,
        offset: 0,
      ),
    );

    expect(gateway.lastTenantId, 'tenant-1');
    expect(gateway.lastPartnerId, 'partner-1');
    expect(gateway.lastCriteria?.keyword, 'SO-001');
    expect(gateway.lastCriteria?.transactionTypes, {'order'});
    expect(gateway.lastCriteria?.transactionRole, PartnerRole.customer);
    expect(gateway.lastLimit, 20);
    expect(result.totalCount, 1);
    expect(result.items.single.transactionCode, 'SO-001');
    expect(
      result.items.single.sourceNavigation.requiredPermission,
      'sales.order.view',
    );
  });
}
