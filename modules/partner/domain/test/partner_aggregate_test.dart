import 'package:test/test.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

void main() {
  group('Partner aggregate', () {
    test('create person partner emits PartnerCreated', () {
      final partner = Partner.create(
        tenantId: const TenantId('t-1'),
        partnerType: PartnerType.person,
        roleTypes: const [PartnerRoleType.customer],
        personProfile: PersonProfile(
          fullName: 'Nguyen Van A',
          phone: PhoneNumber('0901234567'),
        ),
      );

      expect(partner.status, PartnerStatus.active);
      expect(partner.displayName, 'Nguyen Van A');
      expect(partner.domainEvents, isNotNull);
      expect(partner.domainEvents!.first, isA<PartnerCreatedEvent>());
    });

    test('deactivate then reactivate transitions status', () {
      final partner = Partner.create(
        tenantId: const TenantId('t-1'),
        partnerType: PartnerType.person,
        roleTypes: const [PartnerRoleType.customer],
        personProfile: PersonProfile(
          fullName: 'Nguyen Van A',
          phone: PhoneNumber('0901234567'),
        ),
      );

      partner.deactivate();
      expect(partner.status, PartnerStatus.inactive);
      partner.reactivate();
      expect(partner.status, PartnerStatus.active);
    });

    test('deleted partner cannot mutate', () {
      final partner = Partner.create(
        tenantId: const TenantId('t-1'),
        partnerType: PartnerType.person,
        roleTypes: const [PartnerRoleType.customer],
        personProfile: PersonProfile(
          fullName: 'Nguyen Van A',
          phone: PhoneNumber('0901234567'),
        ),
      );

      partner.softDelete(hasTransactions: false);
      expect(
        () => partner.deactivate(),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });

    test('organization enforces single primary contact', () {
      final partner = Partner.create(
        tenantId: const TenantId('t-1'),
        partnerType: PartnerType.organization,
        roleTypes: const [PartnerRoleType.supplier],
        organizationProfile: OrganizationProfile(
          organizationType: OrganizationType.company,
          organizationName: 'ACME Corp',
          phone: PhoneNumber('0281234567'),
        ),
      );

      partner.addContact(
        OrganizationContact(
          personPartnerId: const PartnerId('p-1'),
          isPrimary: true,
        ),
      );
      partner.addContact(
        OrganizationContact(
          personPartnerId: const PartnerId('p-2'),
          isPrimary: true,
        ),
      );

      final primaries = partner.contacts.where((c) => c.isPrimary).length;
      expect(primaries, 1);
    });

    test('updateProfile ignores opposite profile type for organization', () {
      final partner = Partner.create(
        tenantId: const TenantId('t-1'),
        partnerType: PartnerType.organization,
        roleTypes: const [PartnerRoleType.supplier],
        organizationProfile: OrganizationProfile(
          organizationType: OrganizationType.company,
          organizationName: 'ACME Corp',
          phone: PhoneNumber('0281234567'),
        ),
      );

      // Mistakenly passing personProfile must not attach it (exclusive rule).
      partner.updateProfile(
        personProfile: PersonProfile(
          fullName: 'Should Be Ignored',
          phone: PhoneNumber('0901234567'),
        ),
      );

      expect(partner.personProfile, isNull);
      expect(partner.organizationProfile?.organizationName, 'ACME Corp');
      expect(partner.displayName, 'ACME Corp');
    });
  });
}
