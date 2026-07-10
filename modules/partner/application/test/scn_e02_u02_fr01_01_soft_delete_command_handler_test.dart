import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'support/partner_handler_fakes.dart';

void main() {
  group('scn_e02_u02_fr01_01 soft delete handlers', () {
    test('CheckDeleteEligibilityQueryHandler delegates to read gateway', () async {
      final gateway = RecordingPartnerReadGateway()
        ..deleteEligibility = const DeleteEligibilityDto(eligible: true);
      final handler = CheckDeleteEligibilityQueryHandler(readGateway: gateway);

      final result = await handler.handle(
        CheckDeleteEligibilityQuery(tenantId: 't-1', partnerId: 'p-1'),
      );

      expect(result.eligible, isTrue);
    });

    test('SoftDeletePartnerCommandHandler soft deletes eligible partner', () async {
      final repository = InMemoryPartnerRepository(
        seed: {'t-1:p-1': buildActivePersonPartner(version: 5)},
      );
      final readGateway = RecordingPartnerReadGateway()
        ..deleteEligibility = const DeleteEligibilityDto(eligible: true);
      final commandGateway = RecordingPartnerCommandGateway();
      final handler = SoftDeletePartnerCommandHandler(
        repository: repository,
        readGateway: readGateway,
        commandGateway: commandGateway,
      );

      final result = await handler.handle(
        SoftDeletePartnerCommand(
          tenantId: 't-1',
          actorId: 'u-1',
          partnerId: 'p-1',
          expectedVersion: 5,
        ),
      );

      expect(result.partnerId, 'p-1');
      final updated = await repository.findById(
        tenantId: TenantId('t-1'),
        partnerId: PartnerId('p-1'),
      );
      expect(updated?.status, PartnerStatus.deleted);
      expect(commandGateway.lastSoftDelete?.partnerId, 'p-1');
    });
  });
}
