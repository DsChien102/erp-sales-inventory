import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

import 'support/partner_handler_fakes.dart';

void main() {
  group('scn_e01_u04_fr01_01 GetPartnerDetailQueryHandler', () {
    test('returns partner detail from read gateway', () async {
      final gateway = RecordingPartnerReadGateway()
        ..detailResult = PartnerDetailDto(
          partnerId: 'p-1',
          partnerType: PartnerType.person,
          status: PartnerStatus.active,
          displayName: 'Nguyễn Văn A',
          roles: const [PartnerRoleType.customer],
          expectedVersion: 2,
          availableActions: const [
            PartnerAvailableAction.update,
            PartnerAvailableAction.deactivate,
          ],
          personProfile: const PersonProfileDto(
            fullName: 'Nguyễn Văn A',
            phone: '0901234567',
          ),
        );
      final handler = GetPartnerDetailQueryHandler(readGateway: gateway);

      final result = await handler.handle(
        GetPartnerDetailQuery(tenantId: 't-1', partnerId: 'p-1'),
      );

      expect(result.partnerId, 'p-1');
      expect(result.availableActions, contains(PartnerAvailableAction.deactivate));
    });
  });
}
