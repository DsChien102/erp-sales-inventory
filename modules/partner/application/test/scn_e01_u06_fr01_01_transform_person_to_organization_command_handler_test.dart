import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'support/partner_handler_fakes.dart';

void main() {
  group('scn_e01_u06_fr01_01 TransformPersonToOrganizationCommandHandler', () {
    test('transforms person aggregate and delegates to gateway', () async {
      final repository = InMemoryPartnerRepository(
        seed: {'t-1:p-1': buildActivePersonPartner(version: 6)},
      );
      final gateway = RecordingPartnerCommandGateway();
      final handler = TransformPersonToOrganizationCommandHandler(
        repository: repository,
        commandGateway: gateway,
      );

      final result = await handler.handle(
        TransformPersonToOrganizationCommand(
          tenantId: 't-1',
          actorId: 'u-1',
          partnerId: 'p-1',
          expectedVersion: 6,
          organizationProfile: const OrganizationProfileInput(
            organizationType: OrganizationType.company,
            organizationName: 'Công ty ABC',
            phone: '0281234567',
          ),
        ),
      );

      expect(result.partnerId, 'p-1');
      final updated = await repository.findById(
        tenantId: TenantId('t-1'),
        partnerId: PartnerId('p-1'),
      );
      expect(updated?.partnerType, PartnerType.organization);
      expect(updated?.contacts, isNotEmpty);
    });
  });
}
