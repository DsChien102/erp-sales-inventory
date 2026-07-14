import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

import 'support/partner_handler_fakes.dart';

void main() {
  group('scn_e01_u02_fr01_01 CreatePartnerCommandHandler', () {
    test('validates domain and delegates to command gateway', () async {
      final gateway = RecordingPartnerCommandGateway();
      final handler = CreatePartnerCommandHandler(commandGateway: gateway);

      final result = await handler.handle(
        CreatePartnerCommand(
          tenantId: 't-1',
          actorId: 'u-1',
          partnerType: PartnerType.person,
          roles: const [PartnerRoleType.customer],
          personProfile: const PersonProfileInput(
            fullName: 'Nguyễn Văn A',
            phone: '0901234567',
          ),
        ),
      );

      expect(result.partnerId, 'p-new-1');
      expect(gateway.lastCreate, isNotNull);
      expect(gateway.lastCreate!.personProfile?.fullName, 'Nguyễn Văn A');
    });

    test('validator rejects person partner without profile', () async {
      final validator = CreatePartnerCommandValidator();

      expect(
        () => validator.validate(
          CreatePartnerCommand(
            tenantId: 't-1',
            actorId: 'u-1',
            partnerType: PartnerType.person,
            roles: const [PartnerRoleType.customer],
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
