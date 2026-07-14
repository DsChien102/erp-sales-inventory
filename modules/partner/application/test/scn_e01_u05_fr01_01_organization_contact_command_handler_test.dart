import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';

import 'support/partner_handler_fakes.dart';

void main() {
  group('scn_e01_u05_fr01_01 organization contact command handlers', () {
    test('add organization contact delegates to gateway', () async {
      final gateway = RecordingPartnerCommandGateway();
      final handler = AddOrganizationContactCommandHandler(
        commandGateway: gateway,
      );

      final result = await handler.handle(
        AddOrganizationContactCommand(
          tenantId: 't-1',
          actorId: 'u-1',
          organizationPartnerId: 'org-1',
          personPartnerId: 'person-1',
          isPrimary: true,
        ),
      );

      expect(result.organizationPartnerId, 'org-1');
      expect(result.personPartnerId, 'person-1');
    });

    test('update and remove organization contact delegate to gateway', () async {
      final gateway = RecordingPartnerCommandGateway();
      final updateHandler = UpdateOrganizationContactCommandHandler(
        commandGateway: gateway,
      );
      final removeHandler = RemoveOrganizationContactCommandHandler(
        commandGateway: gateway,
      );

      await updateHandler.handle(
        UpdateOrganizationContactCommand(
          tenantId: 't-1',
          actorId: 'u-1',
          organizationPartnerId: 'org-1',
          personPartnerId: 'person-1',
          contactRole: 'Kế toán',
          isPrimary: false,
          note: 'Ghi chú',
          personProfile: const PersonProfileInput(
            fullName: 'Nguyễn Văn B',
            phone: '0901234567',
            email: 'b@example.com',
          ),
        ),
      );
      expect(gateway.lastUpdateContact?.personProfile?.fullName, 'Nguyễn Văn B');
      expect(gateway.lastUpdateContact?.contactRole, 'Kế toán');
      await removeHandler.handle(
        RemoveOrganizationContactCommand(
          tenantId: 't-1',
          actorId: 'u-1',
          organizationPartnerId: 'org-1',
          personPartnerId: 'person-1',
        ),
      );
    });
  });
}
