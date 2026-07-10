import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_application/testing.dart';
import 'package:vet45_partner_domain/domain.dart';

void main() {
  group('FakePartnerModule', () {
    test('create_person_ok returns partner id', () async {
      final module = FakePartnerModule(
        scenario: FakePartnerScenario.createPersonOk,
      );

      final result = await module.executeCommandAsync(
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
    });

    test('search_mixed_types returns person and organization rows', () async {
      final module = FakePartnerModule(
        scenario: FakePartnerScenario.searchMixedTypes,
      );

      final result = await module.executeQueryAsync(
        SearchPartnersQuery(tenantId: 't-1'),
      );

      expect(result.items, hasLength(2));
      expect(result.items.map((e) => e.partnerType).toSet(), {
        PartnerType.person,
        PartnerType.organization,
      });
    });

    test('create_dup_warning throws DUPLICATE_WARNING', () async {
      final module = FakePartnerModule(
        scenario: FakePartnerScenario.createDupWarning,
      );

      expect(
        () => module.executeCommandAsync(
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
        ),
        throwsA(
          isA<PartnerBlockedException>().having(
            (e) => e.code,
            'code',
            PartnerBlockedCodes.duplicateWarning,
          ),
        ),
      );
    });
  });
}
