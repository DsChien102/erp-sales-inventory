import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_infrastructure/infrastructure.dart';

import 'support/fake_partner_rpc_supabase.dart';

void main() {
  const tenantId = 'tenant-1';

  group('e2e_e01_u04_fr01_01 partner detail integration', () {
    late FakePartnerRpcSupabase supabase;
    late IPartnerModule module;

    setUp(() {
      supabase = FakePartnerRpcSupabase();
      module = PartnerStartup.initializeForTesting(supabase: supabase);
    });

    test('detail_person_active loads person profile via mediator and RPC', () async {
      supabase.registerHandler('get_partner_detail', (params) async {
        expect(params?['p_tenant_id'], tenantId);
        expect(params?['p_partner_id'], 'p-person-1');
        return <String, dynamic>{
          'partner_id': 'p-person-1',
          'partner_type': 'person',
          'status': 'active',
          'display_name': 'Nguyễn Văn A',
          'roles': <String>['customer'],
          'available_actions': <String>['update', 'transform', 'deactivate', 'viewHistory'],
          'expected_version': 3,
          'person_profile': <String, dynamic>{
            'title': 'Ông',
            'full_name': 'Nguyễn Văn A',
            'phone': '0901234567',
            'email': 'a@example.com',
          },
          'organization_profile': null,
          'contacts': <dynamic>[],
          'primary_contact_organization_id': 'p-org-primary',
          'primary_contact_organization_name': 'Công ty Minh Phát',
          'created_at': '2026-07-01T10:00:00.000Z',
          'updated_at': '2026-07-10T08:00:00.000Z',
        };
      });

      final detail = await module.executeQueryAsync(
        GetPartnerDetailQuery(tenantId: tenantId, partnerId: 'p-person-1'),
      );

      expect(detail.partnerId, 'p-person-1');
      expect(detail.partnerType, PartnerType.person);
      expect(detail.status, PartnerStatus.active);
      expect(detail.displayName, 'Nguyễn Văn A');
      expect(detail.roles, [PartnerRoleType.customer]);
      expect(detail.personProfile?.fullName, 'Nguyễn Văn A');
      expect(detail.personProfile?.phone, '0901234567');
      expect(detail.organizationProfile, isNull);
      expect(detail.contacts, isEmpty);
      expect(detail.primaryContactOrganizationId, 'p-org-primary');
      expect(detail.primaryContactOrganizationName, 'Công ty Minh Phát');
      expect(detail.availableActions, contains(PartnerAvailableAction.update));
      expect(detail.availableActions, contains(PartnerAvailableAction.transform));
      expect(supabase.calls.single.functionName, 'get_partner_detail');
    });

    test(
      'detail_organization_with_contacts loads org profile and contacts',
      () async {
        supabase.registerHandler('get_partner_detail', (_) async {
          return <String, dynamic>{
            'partner_id': 'p-org-1',
            'partner_type': 'organization',
            'status': 'active',
            'display_name': 'Công ty ABC',
            'roles': <String>['customer', 'supplier'],
            'available_actions': <String>[
              'update',
              'manageContacts',
              'deactivate',
              'viewHistory',
            ],
            'expected_version': 2,
            'person_profile': null,
            'organization_profile': <String, dynamic>{
              'organization_type': 'company',
              'organization_name': 'Công ty ABC',
              'phone': '0281234567',
              'tax_code': '0312345678',
            },
            'contacts': <Map<String, dynamic>>[
              {
                'person_partner_id': 'p-contact-1',
                'display_name': 'Trần Thị B',
                'phone': '0907654321',
                'contact_role': 'primary',
                'is_primary': true,
              },
              {
                'person_partner_id': 'p-contact-inactive',
                'display_name': 'Lê Văn C',
                'phone': '0907000000',
                'contact_role': 'Giao nhận',
                'is_primary': false,
                'status': 'inactive',
              },
            ],
            'created_at': '2026-06-01T00:00:00.000Z',
            'updated_at': '2026-07-09T12:00:00.000Z',
          };
        });

        final detail = await module.executeQueryAsync(
          GetPartnerDetailQuery(tenantId: tenantId, partnerId: 'p-org-1'),
        );

        expect(detail.partnerType, PartnerType.organization);
        expect(detail.roles, hasLength(2));
        expect(detail.organizationProfile?.organizationName, 'Công ty ABC');
        expect(detail.organizationProfile?.taxCode, '0312345678');
        expect(detail.contacts, hasLength(2));
        expect(detail.contacts.first.isPrimary, isTrue);
        expect(detail.contacts.first.displayName, 'Trần Thị B');
        expect(detail.contacts.first.contactRole, isNull);
        expect(detail.contacts.last.status, PartnerStatus.inactive);
        expect(
          detail.availableActions,
          contains(PartnerAvailableAction.manageContacts),
        );
      },
    );

    test('detail maps business_household organization type', () async {
      supabase.registerHandler('get_partner_detail', (_) async {
        return <String, dynamic>{
          'partner_id': 'p-business-household-1',
          'partner_type': 'organization',
          'status': 'active',
          'display_name': 'Hộ kinh doanh An Phát',
          'roles': <String>['supplier'],
          'available_actions': <String>['update'],
          'expected_version': 1,
          'person_profile': null,
          'organization_profile': <String, dynamic>{
            'organization_type': 'business_household',
            'organization_name': 'Hộ kinh doanh An Phát',
            'phone': '0901234567',
          },
          'contacts': <Map<String, dynamic>>[],
          'created_at': '2026-07-13T00:00:00.000Z',
          'updated_at': '2026-07-13T00:00:00.000Z',
        };
      });

      final detail = await module.executeQueryAsync(
        GetPartnerDetailQuery(
          tenantId: tenantId,
          partnerId: 'p-business-household-1',
        ),
      );

      expect(
        detail.organizationProfile?.organizationType,
        OrganizationType.businessHousehold,
      );
    });

    test('detail_deleted surfaces NOT_FOUND via RPC error mapping', () async {
      supabase.registerHandler('get_partner_detail', (_) async {
        throw Exception('NOT_FOUND: partner is deleted');
      });

      await expectLater(
        module.executeQueryAsync(
          GetPartnerDetailQuery(tenantId: tenantId, partnerId: 'p-deleted'),
        ),
        throwsA(
          isA<PartnerBlockedException>().having(
            (e) => e.code,
            'code',
            PartnerBlockedCodes.notFound,
          ),
        ),
      );
    });

    test('missing permission surfaces NO_PERMISSION', () async {
      supabase.registerHandler('get_partner_detail', (_) async {
        throw Exception('permission denied: partner.detail.view');
      });

      await expectLater(
        module.executeQueryAsync(
          GetPartnerDetailQuery(tenantId: tenantId, partnerId: 'p-1'),
        ),
        throwsA(
          isA<PartnerBlockedException>().having(
            (e) => e.code,
            'code',
            PartnerBlockedCodes.noPermission,
          ),
        ),
      );
    });
  });
}
