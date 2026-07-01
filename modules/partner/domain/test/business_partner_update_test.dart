import 'package:test/test.dart';
import 'package:vet45_partner_domain/src/business_partner/business_partner.dart';
import 'package:vet45_partner_domain/src/business_partner/events/partner_profile_updated.dart';
import 'package:vet45_partner_domain/src/ids/business_partner_id.dart';
import 'package:vet45_partner_domain/src/shared/entity_type.dart';
import 'package:vet45_partner_domain/src/shared/partner_role.dart';
import 'package:vet45_partner_domain/src/shared/partner_status.dart';
import 'package:vet45_partner_domain/src/value_objects/partner_name.dart';
import 'package:vet45_partner_domain/src/value_objects/phone_number.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

void main() {
  final createdAt = DateTime.parse('2026-06-01T00:00:00Z');

  BusinessPartner basePartner() {
    return BusinessPartner.rehydrate(
      id: const BusinessPartnerId('p_1'),
      tenantId: const TenantId('t_1'),
      entityType: EntityType.individual,
      displayName: PartnerName('Nguyen Van A'),
      individualName: PartnerName('Nguyen Van A'),
      phone: PhoneNumber('0987654321'),
      roles: {PartnerRole.customer},
      status: PartnerStatus.active,
      createdBy: 'u_1',
      createdAt: createdAt,
      updatedBy: 'u_1',
      updatedAt: createdAt,
      version: 1,
    );
  }

  group('BusinessPartner.updateProfile', () {
    test('updates profile and emits PartnerProfileUpdated', () {
      final partner = basePartner();
      final updated = partner.updateProfile(
        entityType: EntityType.individual,
        displayName: PartnerName('Nguyen Van B'),
        individualName: PartnerName('Nguyen Van B'),
        phone: PhoneNumber('0912345678'),
        roles: {PartnerRole.customer, PartnerRole.supplier},
        actorId: 'u_2',
        now: DateTime.parse('2026-06-02T00:00:00Z'),
      );

      expect(updated.displayName.value, 'Nguyen Van B');
      expect(updated.phone.value, '0912345678');
      expect(updated.updatedBy, 'u_2');
      expect(updated.hasRole(PartnerRole.supplier), isTrue);
      expect(updated.domainEvents, hasLength(1));
      expect(updated.domainEvents!.first, isA<PartnerProfileUpdated>());
    });

    test('throws when no role provided after update', () {
      final partner = basePartner();

      expect(
        () => partner.updateProfile(
          entityType: EntityType.individual,
          displayName: PartnerName('Valid Name'),
          individualName: PartnerName('Valid Name'),
          phone: PhoneNumber('0987654321'),
          roles: const {},
          actorId: 'u_2',
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });
  });
}
