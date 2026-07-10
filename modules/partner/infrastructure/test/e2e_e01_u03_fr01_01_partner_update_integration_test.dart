import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_infrastructure/infrastructure.dart';

import 'support/fake_partner_rpc_supabase.dart';

void main() {
  const tenantId = 'tenant-1';
  const actorId = 'user-1';

  Map<String, dynamic> personDetail({
    required String partnerId,
    required int expectedVersion,
  }) {
    return <String, dynamic>{
      'partner_id': partnerId,
      'partner_type': 'person',
      'status': 'active',
      'display_name': 'Nguyễn Văn A',
      'roles': <String>['customer'],
      'available_actions': <String>['update', 'transform', 'deactivate'],
      'expected_version': expectedVersion,
      'person_profile': <String, dynamic>{
        'title': 'Ông',
        'full_name': 'Nguyễn Văn A',
        'phone': '0901234567',
        'email': 'a@example.com',
      },
      'organization_profile': null,
      'contacts': <dynamic>[],
      'created_at': '2026-07-01T10:00:00.000Z',
      'updated_at': '2026-07-10T08:00:00.000Z',
    };
  }

  Map<String, dynamic> organizationDetail({
    required String partnerId,
    required int expectedVersion,
  }) {
    return <String, dynamic>{
      'partner_id': partnerId,
      'partner_type': 'organization',
      'status': 'active',
      'display_name': 'Công ty ABC',
      'roles': <String>['supplier'],
      'available_actions': <String>['update', 'manageContacts', 'deactivate'],
      'expected_version': expectedVersion,
      'person_profile': null,
      'organization_profile': <String, dynamic>{
        'organization_type': 'company',
        'organization_name': 'Công ty ABC',
        'phone': '0281234567',
        'tax_code': '0312345678',
      },
      'contacts': <dynamic>[],
      'created_at': '2026-06-01T00:00:00.000Z',
      'updated_at': '2026-07-09T12:00:00.000Z',
    };
  }

  group('e2e_e01_u03_fr01_01 partner update integration', () {
    late FakePartnerRpcSupabase supabase;
    late IPartnerModule module;

    setUp(() {
      supabase = FakePartnerRpcSupabase();
      module = PartnerStartup.initializeForTesting(supabase: supabase);
    });

    test('person update succeeds via mediator and RPC', () async {
      supabase.registerHandler('get_partner_detail', (params) async {
        expect(params?['p_tenant_id'], tenantId);
        expect(params?['p_partner_id'], 'p-person-1');
        return personDetail(partnerId: 'p-person-1', expectedVersion: 3);
      });
      supabase.registerHandler('update_partner', (params) async {
        expect(params?['p_tenant_id'], tenantId);
        expect(params?['p_actor_id'], actorId);
        expect(params?['p_partner_id'], 'p-person-1');
        expect(params?['p_expected_version'], 3);
        expect(params?['p_roles'], ['customer', 'supplier']);
        expect(params?['p_confirm_duplicate'], false);
        final profile = params?['p_person_profile'] as Map<String, dynamic>;
        expect(profile['full_name'], 'Trần Thị Hoa');
        expect(profile['phone'], '0987654321');
        return [
          {
            'partner_id': 'p-person-1',
            'expected_version': 4,
            'warnings': <dynamic>[],
          },
        ];
      });

      final result = await module.executeCommandAsync(
        UpdatePartnerProfileCommand(
          tenantId: tenantId,
          actorId: actorId,
          partnerId: 'p-person-1',
          expectedVersion: 3,
          roles: const [PartnerRoleType.customer, PartnerRoleType.supplier],
          personProfile: const PersonProfileInput(
            fullName: 'Trần Thị Hoa',
            phone: '0987654321',
          ),
        ),
      );

      expect(result.partnerId, 'p-person-1');
      expect(result.expectedVersion, 4);
      expect(
        supabase.calls.map((c) => c.functionName),
        ['get_partner_detail', 'update_partner'],
      );
    });

    test('organization update succeeds via mediator and RPC', () async {
      supabase.registerHandler('get_partner_detail', (_) async {
        return organizationDetail(partnerId: 'p-org-1', expectedVersion: 2);
      });
      supabase.registerHandler('update_partner', (params) async {
        expect(params?['p_partner_id'], 'p-org-1');
        expect(params?['p_expected_version'], 2);
        final profile = params?['p_organization_profile'] as Map<String, dynamic>;
        expect(profile['organization_name'], 'Công ty ABC Updated');
        expect(profile['phone'], '0289999999');
        return [
          {
            'partner_id': 'p-org-1',
            'expected_version': 3,
            'warnings': <dynamic>[],
          },
        ];
      });

      final result = await module.executeCommandAsync(
        UpdatePartnerProfileCommand(
          tenantId: tenantId,
          actorId: actorId,
          partnerId: 'p-org-1',
          expectedVersion: 2,
          roles: const [PartnerRoleType.supplier],
          organizationProfile: const OrganizationProfileInput(
            organizationType: OrganizationType.company,
            organizationName: 'Công ty ABC Updated',
            phone: '0289999999',
          ),
        ),
      );

      expect(result.partnerId, 'p-org-1');
      expect(result.expectedVersion, 3);
      expect(supabase.calls.last.functionName, 'update_partner');
    });

    test('version mismatch surfaces STATE_CHANGED before write RPC', () async {
      supabase.registerHandler('get_partner_detail', (_) async {
        return personDetail(partnerId: 'p-person-1', expectedVersion: 5);
      });

      await expectLater(
        module.executeCommandAsync(
          UpdatePartnerProfileCommand(
            tenantId: tenantId,
            actorId: actorId,
            partnerId: 'p-person-1',
            expectedVersion: 3,
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
            PartnerBlockedCodes.stateChanged,
          ),
        ),
      );

      expect(
        supabase.calls.map((c) => c.functionName),
        ['get_partner_detail'],
      );
    });

    test('update without confirmDuplicate surfaces DUPLICATE_WARNING', () async {
      supabase.registerHandler('get_partner_detail', (_) async {
        return personDetail(partnerId: 'p-person-1', expectedVersion: 1);
      });
      supabase.registerHandler('update_partner', (params) async {
        if (params?['p_confirm_duplicate'] != true) {
          throw Exception('DUPLICATE_WARNING: phone already exists');
        }
        return [
          {
            'partner_id': 'p-person-1',
            'expected_version': 2,
            'warnings': <dynamic>[],
          },
        ];
      });

      await expectLater(
        module.executeCommandAsync(
          UpdatePartnerProfileCommand(
            tenantId: tenantId,
            actorId: actorId,
            partnerId: 'p-person-1',
            expectedVersion: 1,
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
        UpdatePartnerProfileCommand(
          tenantId: tenantId,
          actorId: actorId,
          partnerId: 'p-person-1',
          expectedVersion: 1,
          roles: const [PartnerRoleType.customer],
          personProfile: const PersonProfileInput(
            fullName: 'Nguyễn Văn A',
            phone: '0901234567',
          ),
          confirmDuplicate: true,
        ),
      );

      expect(result.partnerId, 'p-person-1');
      expect(result.expectedVersion, 2);
    });

    test('check_duplicate forwards exclude_partner_id for edit', () async {
      supabase.registerHandler('check_duplicate', (params) async {
        expect(params?['p_exclude_partner_id'], 'p-person-1');
        expect(params?['p_phone'], '0901234567');
        return <dynamic>[];
      });

      final matches = await module.executeQueryAsync(
        CheckDuplicatePartnersQuery(
          tenantId: tenantId,
          phone: '0901234567',
          excludePartnerId: 'p-person-1',
        ),
      );

      expect(matches, isEmpty);
      expect(supabase.calls.single.functionName, 'check_duplicate');
    });
  });
}
