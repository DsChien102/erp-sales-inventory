import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_infrastructure/infrastructure.dart';

import 'support/fake_partner_rpc_supabase.dart';

void main() {
  const tenantId = 'tenant-1';
  const actorId = 'user-1';

  group('e2e_e01_u02_fr06_01 partner create integration', () {
    late FakePartnerRpcSupabase supabase;
    late IPartnerModule module;

    setUp(() {
      supabase = FakePartnerRpcSupabase();
      module = PartnerStartup.initializeForTesting(supabase: supabase);
    });

    test('person create succeeds via mediator and RPC', () async {
      supabase.registerHandler('create_partner', (_) async {
        return [
          {
            'partner_id': 'p-new-person-1',
            'warnings': <dynamic>[],
          },
        ];
      });

      final result = await module.executeCommandAsync(
        CreatePartnerCommand(
          tenantId: tenantId,
          actorId: actorId,
          partnerType: PartnerType.person,
          roles: const [PartnerRoleType.customer],
          personProfile: const PersonProfileInput(
            fullName: 'Nguyễn Văn A',
            phone: '0901234567',
            taxCode: '2201018000',
            invoice: InvoiceProfileInput(
              invoiceAddress: '12 Nguyễn Huệ, Quận 1',
            ),
          ),
        ),
      );

      expect(result.partnerId, 'p-new-person-1');
      expect(supabase.calls, hasLength(1));
      expect(supabase.calls.single.functionName, 'create_partner');
      expect(supabase.calls.single.params?['p_command_id'], isNull);
      expect(supabase.calls.single.params?['p_partner_type'], 'person');
      final profile =
          supabase.calls.single.params?['p_person_profile'] as Map<String, dynamic>;
      expect(profile['invoice'], isA<Map>());
      expect(
        (profile['invoice'] as Map)['address'],
        '12 Nguyễn Huệ, Quận 1',
      );
      expect(profile['invoice_address'], '12 Nguyễn Huệ, Quận 1');
    });

    test('check_duplicate derives match levels from matched_field', () async {
      supabase.registerHandler('check_duplicate', (_) async {
        return [
          {
            'partner_id': 'p-dup-phone',
            'display_name': 'Trùng SĐT',
            'matched_field': 'phone',
            'partner_type': 'person',
            'matched_value': '0901234567',
          },
          {
            'partner_id': 'p-dup-tax',
            'display_name': 'Trùng MST',
            'matched_field': 'tax_code',
            'partner_type': 'organization',
            'matched_value': '0312345678',
          },
          {
            'partner_id': 'p-dup-name',
            'display_name': 'Trùng tên',
            'matched_field': 'name',
            'partner_type': 'person',
            'matched_value': 'Nguyễn Văn A',
          },
        ];
      });

      final matches = await module.executeQueryAsync(
        CheckDuplicatePartnersQuery(
          tenantId: tenantId,
          phone: '0901234567',
          taxCode: '0312345678',
          name: 'Nguyễn Văn A',
        ),
      );

      expect(matches, hasLength(3));
      expect(
        matches.firstWhere((m) => m.matchedField == PartnerDuplicateMatchField.phone).matchLevel,
        PartnerDuplicateMatchLevel.exact,
      );
      expect(
        matches.firstWhere((m) => m.matchedField == PartnerDuplicateMatchField.taxCode).matchLevel,
        PartnerDuplicateMatchLevel.exact,
      );
      expect(
        matches.firstWhere((m) => m.matchedField == PartnerDuplicateMatchField.name).matchLevel,
        PartnerDuplicateMatchLevel.possible,
      );
    });

    test('create without confirmDuplicate surfaces DUPLICATE_WARNING', () async {
      supabase.registerHandler('create_partner', (params) async {
        if (params?['p_confirm_duplicate'] != true) {
          throw Exception('DUPLICATE_WARNING: phone already exists');
        }
        return [
          {
            'partner_id': 'p-new-confirmed',
            'warnings': <dynamic>[],
          },
        ];
      });

      await expectLater(
        module.executeCommandAsync(
          CreatePartnerCommand(
            tenantId: tenantId,
            actorId: actorId,
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

      final result = await module.executeCommandAsync(
        CreatePartnerCommand(
          tenantId: tenantId,
          actorId: actorId,
          partnerType: PartnerType.person,
          roles: const [PartnerRoleType.customer],
          personProfile: const PersonProfileInput(
            fullName: 'Nguyễn Văn A',
            phone: '0901234567',
          ),
          confirmDuplicate: true,
        ),
      );

      expect(result.partnerId, 'p-new-confirmed');
    });

    test('organization create succeeds without primary contact', () async {
      supabase.registerHandler('create_partner', (_) async {
        return [
          {
            'partner_id': 'p-new-org-1',
            'warnings': <dynamic>[],
          },
        ];
      });

      final result = await module.executeCommandAsync(
        CreatePartnerCommand(
          tenantId: tenantId,
          actorId: actorId,
          partnerType: PartnerType.organization,
          roles: const [PartnerRoleType.supplier],
          organizationProfile: const OrganizationProfileInput(
            organizationType: OrganizationType.company,
            organizationName: 'Công ty TNHH An Phát',
            phone: '0281234567',
          ),
        ),
      );

      expect(result.partnerId, 'p-new-org-1');
      expect(supabase.calls.single.params?['p_partner_type'], 'organization');
      expect(supabase.calls.single.params?['p_organization_profile'], isNotNull);
    });
  });
}
