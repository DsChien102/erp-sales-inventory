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

    test('organization create keeps optional primary contact in command', () {
      const primaryContact = PersonProfileInput(
        fullName: 'Trần Thị Lan',
        phone: '0903456789',
      );

      final command = CreatePartnerCommand(
        tenantId: 't-1',
        actorId: 'u-1',
        partnerType: PartnerType.organization,
        roles: const [PartnerRoleType.supplier],
        organizationProfile: const OrganizationProfileInput(
          organizationType: OrganizationType.company,
          organizationName: 'Công ty TNHH An Phát',
          phone: '02812345678',
        ),
        organizationPrimaryContact: primaryContact,
      );

      expect(command.organizationPrimaryContact, same(primaryContact));
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

    test('search_by_contact returns the linked organization once', () async {
      final module = FakePartnerModule(
        scenario: FakePartnerScenario.searchByContact,
      );

      final result = await module.executeQueryAsync(
        SearchPartnersQuery(tenantId: 't-1', query: 'Trần Thị B'),
      );

      expect(result.items, hasLength(1));
      expect(result.total, 1);
      expect(result.items.single.partnerId, 'p-org-contact-match');
      expect(result.items.single.partnerType, PartnerType.organization);
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

    test('create_dup_warning query returns possible match', () async {
      final module = FakePartnerModule(
        scenario: FakePartnerScenario.createDupWarning,
      );

      final matches = await module.executeQueryAsync(
        CheckDuplicatePartnersQuery(
          tenantId: 't-1',
          phone: '0901234567',
        ),
      );

      expect(matches, hasLength(1));
      expect(matches.single.matchLevel, PartnerDuplicateMatchLevel.possible);
    });

    test('create_exact_duplicate query returns exact match', () async {
      final module = FakePartnerModule(
        scenario: FakePartnerScenario.createExactDuplicate,
      );

      final matches = await module.executeQueryAsync(
        CheckDuplicatePartnersQuery(
          tenantId: 't-1',
          taxCode: '0101234567',
        ),
      );

      expect(matches, hasLength(1));
      expect(matches.single.matchLevel, PartnerDuplicateMatchLevel.exact);
    });
  });
}
