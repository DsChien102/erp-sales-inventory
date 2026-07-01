import 'package:test/test.dart';
import 'package:vet45_partner_domain/src/business_partner/business_partner.dart';
import 'package:vet45_partner_domain/src/ids/business_partner_id.dart';
import 'package:vet45_partner_domain/src/shared/entity_type.dart';
import 'package:vet45_partner_domain/src/shared/partner_role.dart';
import 'package:vet45_partner_domain/src/shared/partner_status.dart';
import 'package:vet45_partner_domain/src/value_objects/partner_name.dart';
import 'package:vet45_partner_domain/src/value_objects/phone_number.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

void main() {
  group('BusinessPartner.register', () {
    test('creates partner with active status and domain event', () {
      final partner = BusinessPartner.register(
        id: const BusinessPartnerId('p_1'),
        tenantId: const TenantId('t_1'),
        entityType: EntityType.individual,
        displayName: PartnerName('Nguyen Van A'),
        individualName: PartnerName('Nguyen Van A'),
        phone: PhoneNumber('0987654321'),
        roles: {PartnerRole.customer},
        actorId: 'u_1',
      );

      expect(partner.status, PartnerStatus.active);
      expect(partner.hasRole(PartnerRole.customer), isTrue);
      expect(partner.domainEvents, isNotNull);
      expect(partner.domainEvents, hasLength(1));
    });

    test('throws when no role provided', () {
      expect(
        () => BusinessPartner.register(
          id: const BusinessPartnerId('p_2'),
          tenantId: const TenantId('t_1'),
          entityType: EntityType.individual,
          displayName: PartnerName('Nguyen Van B'),
          individualName: PartnerName('Nguyen Van B'),
          phone: PhoneNumber('0987654321'),
          roles: const {},
          actorId: 'u_1',
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });

    test('throws when company missing company name', () {
      expect(
        () => BusinessPartner.register(
          id: const BusinessPartnerId('p_3'),
          tenantId: const TenantId('t_1'),
          entityType: EntityType.company,
          displayName: PartnerName('Cong ty C'),
          phone: PhoneNumber('0987654321'),
          roles: {PartnerRole.supplier},
          actorId: 'u_1',
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });
  });
}
