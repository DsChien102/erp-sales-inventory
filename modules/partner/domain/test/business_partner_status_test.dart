import 'package:test/test.dart';
import 'package:vet45_partner_domain/src/business_partner/business_partner.dart';
import 'package:vet45_partner_domain/src/ids/business_partner_id.dart';
import 'package:vet45_partner_domain/src/shared/entity_type.dart';
import 'package:vet45_partner_domain/src/shared/partner_role.dart';
import 'package:vet45_partner_domain/src/shared/partner_status.dart';
import 'package:vet45_partner_domain/src/value_objects/partner_name.dart';
import 'package:vet45_partner_domain/src/value_objects/phone_number.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

BusinessPartner _activePartner() {
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
    createdAt: DateTime.parse('2026-07-01T00:00:00Z'),
    updatedBy: 'u_1',
    updatedAt: DateTime.parse('2026-07-01T00:00:00Z'),
    version: 2,
  );
}

void main() {
  group('BusinessPartner status transitions', () {
    test('deactivate moves active partner to inactive and emits event', () {
      final partner = _activePartner();

      final deactivated = partner.deactivate(actorId: 'u_2');

      expect(deactivated.status, PartnerStatus.inactive);
      expect(deactivated.updatedBy, 'u_2');
      expect(deactivated.domainEvents, hasLength(1));
    });

    test('reactivate moves inactive partner to active and emits event', () {
      final inactive = _activePartner().deactivate(actorId: 'u_2');

      final reactivated = inactive.reactivate(actorId: 'u_3');

      expect(reactivated.status, PartnerStatus.active);
      expect(reactivated.updatedBy, 'u_3');
      expect(reactivated.domainEvents, hasLength(1));
    });

    test('deactivate rejects inactive partner', () {
      final inactive = _activePartner().deactivate(actorId: 'u_2');

      expect(
        () => inactive.deactivate(actorId: 'u_3'),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });

    test('reactivate rejects active partner', () {
      final partner = _activePartner();

      expect(
        () => partner.reactivate(actorId: 'u_2'),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });
  });
}
