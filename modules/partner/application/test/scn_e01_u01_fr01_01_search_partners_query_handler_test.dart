import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

import 'support/partner_handler_fakes.dart';

void main() {
  group('scn_e01_u01_fr01_01 SearchPartnersQueryHandler', () {
    test('returns search result from read gateway', () async {
      final gateway = RecordingPartnerReadGateway()
        ..searchResult = PartnerSearchResultDto(
          items: [
            PartnerListItemDto(
              partnerId: 'p-1',
              partnerType: PartnerType.person,
              displayName: 'Nguyễn Văn A',
              status: PartnerStatus.active,
              roles: const [PartnerRoleType.customer],
              phone: '0901234567',
            ),
          ],
          total: 1,
          page: 1,
          limit: 20,
        );
      final handler = SearchPartnersQueryHandler(readGateway: gateway);

      final result = await handler.handle(
        SearchPartnersQuery(tenantId: 't-1', updatedWithinDays: 7),
      );

      expect(result.items, hasLength(1));
      expect(gateway.lastSearch?.tenantId, 't-1');
      expect(gateway.lastSearch?.updatedWithinDays, 7);
    });
  });
}
