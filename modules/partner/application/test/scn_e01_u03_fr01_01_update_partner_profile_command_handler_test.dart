import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'support/partner_handler_fakes.dart';

void main() {
  group('scn_e01_u03_fr01_01 UpdatePartnerProfileCommandHandler', () {
    test('loads aggregate, mutates profile, delegates to gateway', () async {
      final partner = buildActivePersonPartner(version: 2);
      final repository = InMemoryPartnerRepository(
        seed: {'t-1:p-1': partner},
      );
      final gateway = RecordingPartnerCommandGateway();
      final handler = UpdatePartnerProfileCommandHandler(
        repository: repository,
        commandGateway: gateway,
      );

      final result = await handler.handle(
        UpdatePartnerProfileCommand(
          tenantId: 't-1',
          actorId: 'u-1',
          partnerId: 'p-1',
          expectedVersion: 2,
          roles: const [PartnerRoleType.customer, PartnerRoleType.supplier],
          personProfile: const PersonProfileInput(
            fullName: 'Nguyễn Văn B',
            phone: '0901234567',
          ),
        ),
      );

      expect(result.partnerId, 'p-1');
      expect(gateway.lastUpdateProfile?.personProfile?.fullName, 'Nguyễn Văn B');
      final updated = await repository.findById(
        tenantId: TenantId('t-1'),
        partnerId: PartnerId('p-1'),
      );
      expect(updated?.displayName, 'Nguyễn Văn B');
      expect(updated?.roles, hasLength(2));
    });

    test('throws STATE_CHANGED when version mismatches', () async {
      final repository = InMemoryPartnerRepository(
        seed: {'t-1:p-1': buildActivePersonPartner(version: 2)},
      );
      final handler = UpdatePartnerProfileCommandHandler(
        repository: repository,
        commandGateway: RecordingPartnerCommandGateway(),
      );

      expect(
        () => handler.handle(
          UpdatePartnerProfileCommand(
            tenantId: 't-1',
            actorId: 'u-1',
            partnerId: 'p-1',
            expectedVersion: 1,
            roles: const [PartnerRoleType.customer],
            personProfile: const PersonProfileInput(
              fullName: 'Nguyễn Văn B',
              phone: '0901234567',
            ),
          ),
        ),
        throwsA(
          isA<PartnerBlockedException>().having(
            (e) => e.code,
            'code',
            PartnerBlockedCodes.stateChanged,
          ),
        ),
      );
    });
  });
}
