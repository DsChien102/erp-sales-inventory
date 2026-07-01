import 'package:test/test.dart';
import 'package:vet45_partner_domain/src/business_partner/business_partner.dart';
import 'package:vet45_partner_domain/src/business_partner/events/partner_deleted.dart';
import 'package:vet45_partner_domain/src/ids/business_partner_id.dart';
import 'package:vet45_partner_domain/src/shared/entity_type.dart';
import 'package:vet45_partner_domain/src/shared/partner_role.dart';
import 'package:vet45_partner_domain/src/shared/partner_status.dart';
import 'package:vet45_partner_domain/src/value_objects/partner_name.dart';
import 'package:vet45_partner_domain/src/value_objects/phone_number.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

BusinessPartner _partner() {
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
  group('BusinessPartner.delete', () {
    test('scn_e02_u02_fr03_01 deletes when no transaction history', () {
      final partner = _partner();

      final deleted = partner.delete(
        actorId: 'u_2',
        hasTransactionHistory: false,
      );

      expect(deleted.updatedBy, 'u_2');
      expect(deleted.domainEvents, hasLength(1));
      expect(deleted.domainEvents!.single, isA<PartnerDeleted>());
    });

    test('rejects delete when partner has transaction history', () {
      final partner = _partner();

      expect(
        () => partner.delete(
          actorId: 'u_2',
          hasTransactionHistory: true,
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });
  });
}
