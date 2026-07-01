import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

class _FakePartnerReadGateway implements IPartnerReadGateway {
  String? lastTenantId;
  String? lastPartnerId;

  PartnerDetailDto? detailToReturn;

  @override
  Future<PartnerDetailDto?> getDetail({
    required String tenantId,
    required String partnerId,
  }) async {
    lastTenantId = tenantId;
    lastPartnerId = partnerId;
    return detailToReturn;
  }

  @override
  Future<PartnerSearchResultDto> search({
    required String tenantId,
    required PartnerSearchCriteria criteria,
    int limit = 100,
    int offset = 0,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  group('GetPartnerDetailQueryHandler', () {
    test('returns detail from read gateway', () async {
      final gateway = _FakePartnerReadGateway()
        ..detailToReturn = PartnerDetailDto(
          id: 'partner-1',
          displayName: 'Nguyen Van A',
          phone: '0987654321',
          roles: {PartnerRole.customer},
          entityType: EntityType.individual,
          status: PartnerStatus.active,
          createdAt: DateTime.parse('2026-06-01T00:00:00Z'),
          updatedAt: DateTime.parse('2026-06-02T00:00:00Z'),
          version: 1,
          createdBy: 'user-1',
          updatedBy: 'user-1',
        );

      final handler = GetPartnerDetailQueryHandler(readGateway: gateway);
      final result = await handler.handle(
        GetPartnerDetailQuery(
          tenantId: 'tenant-1',
          partnerId: 'partner-1',
        ),
      );

      expect(gateway.lastTenantId, 'tenant-1');
      expect(gateway.lastPartnerId, 'partner-1');
      expect(result?.displayName, 'Nguyen Van A');
    });

    test('returns null when partner not found', () async {
      final gateway = _FakePartnerReadGateway()..detailToReturn = null;
      final handler = GetPartnerDetailQueryHandler(readGateway: gateway);

      final result = await handler.handle(
        GetPartnerDetailQuery(
          tenantId: 'tenant-1',
          partnerId: 'missing',
        ),
      );

      expect(result, isNull);
    });
  });
}
