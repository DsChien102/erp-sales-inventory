import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'support/partner_handler_fakes.dart';

void main() {
  group('scn_e02_u01_fr01_01 status command handlers', () {
    test('deactivate loads aggregate and delegates to gateway', () async {
      final repository = InMemoryPartnerRepository(
        seed: {'t-1:p-1': buildActivePersonPartner(version: 3)},
      );
      final gateway = RecordingPartnerCommandGateway();
      final handler = DeactivatePartnerCommandHandler(
        repository: repository,
        commandGateway: gateway,
      );

      final result = await handler.handle(
        DeactivatePartnerCommand(
          tenantId: 't-1',
          actorId: 'u-1',
          partnerId: 'p-1',
          expectedVersion: 3,
        ),
      );

      expect(result.partnerId, 'p-1');
      final updated = await repository.findById(
        tenantId: TenantId('t-1'),
        partnerId: PartnerId('p-1'),
      );
      expect(updated?.status, PartnerStatus.inactive);
      expect(gateway.lastDeactivate?.partnerId, 'p-1');
    });

    test('reactivate inactive partner', () async {
      final inactive = buildActivePersonPartner(version: 4)
        ..deactivate();
      final repository = InMemoryPartnerRepository(seed: {'t-1:p-1': inactive});
      final gateway = RecordingPartnerCommandGateway();
      final handler = ReactivatePartnerCommandHandler(
        repository: repository,
        commandGateway: gateway,
      );

      final result = await handler.handle(
        ReactivatePartnerCommand(
          tenantId: 't-1',
          actorId: 'u-1',
          partnerId: 'p-1',
          expectedVersion: 4,
        ),
      );

      expect(result.partnerId, 'p-1');
      final updated = await repository.findById(
        tenantId: TenantId('t-1'),
        partnerId: PartnerId('p-1'),
      );
      expect(updated?.status, PartnerStatus.active);
      expect(gateway.lastReactivate?.partnerId, 'p-1');
    });
  });
}
