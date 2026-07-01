import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

class _RecordingPartnerReadGateway implements IPartnerReadGateway {
  String? lastTenantId;
  PartnerSearchCriteria? lastCriteria;
  int? lastLimit;
  int? lastOffset;

  @override
  Future<PartnerSearchResultDto> search({
    required String tenantId,
    required PartnerSearchCriteria criteria,
    int limit = 100,
    int offset = 0,
  }) async {
    lastTenantId = tenantId;
    lastCriteria = criteria;
    lastLimit = limit;
    lastOffset = offset;

    return PartnerSearchResultDto(
      items: [
        PartnerListItemDto(
          id: 'partner-1',
          displayName: 'Nguyen Van A',
          phone: '0987654321',
          roles: {PartnerRole.customer},
          entityType: EntityType.individual,
          status: PartnerStatus.active,
          updatedAt: DateTime.parse('2026-06-30T10:00:00Z'),
        ),
      ],
      totalCount: 1,
    );
  }

  @override
  Future<PartnerDetailDto?> getDetail({
    required String tenantId,
    required String partnerId,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  test('SearchPartnersQueryHandler delegates to read gateway', () async {
    final gateway = _RecordingPartnerReadGateway();
    final handler = SearchPartnersQueryHandler(readGateway: gateway);
    final criteria = PartnerSearchCriteria(
      keyword: 'Nguyen',
      roleFilter: PartnerRoleFilter.customer,
    );

    final result = await handler.handle(
      SearchPartnersQuery(
        tenantId: 'tenant-1',
        criteria: criteria,
        limit: 25,
        offset: 5,
      ),
    );

    expect(gateway.lastTenantId, 'tenant-1');
    expect(gateway.lastCriteria, criteria);
    expect(gateway.lastLimit, 25);
    expect(gateway.lastOffset, 5);
    expect(result.totalCount, 1);
    expect(result.items.single.displayName, 'Nguyen Van A');
    expect(criteria.activeOnly, isTrue);
  });
}
