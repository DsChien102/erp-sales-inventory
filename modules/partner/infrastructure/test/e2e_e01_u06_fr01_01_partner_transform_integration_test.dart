import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_infrastructure/infrastructure.dart';

import 'support/fake_partner_rpc_supabase.dart';

void main() {
  const tenantId = 'tenant-1';
  const actorId = 'user-1';

  group('e2e_e01_u06_fr01_01 partner transform integration', () {
    late FakePartnerRpcSupabase supabase;
    late IPartnerModule module;

    setUp(() {
      supabase = FakePartnerRpcSupabase();
      module = PartnerStartup.initializeForTesting(supabase: supabase);
    });

    test('person transform succeeds via mediator and RPC', () async {
      supabase.registerHandler('get_partner_detail', (params) async {
        expect(params?['p_partner_id'], 'p-person-1');
        return <String, dynamic>{
          'partner_id': 'p-person-1',
          'partner_type': 'person',
          'status': 'active',
          'display_name': 'Nguyễn Văn A',
          'roles': <String>['customer'],
          'available_actions': <String>['transform'],
          'expected_version': 2,
          'person_profile': <String, dynamic>{
            'full_name': 'Nguyễn Văn A',
            'phone': '0901234567',
          },
          'organization_profile': null,
          'contacts': <dynamic>[],
          'created_at': '2026-07-01T10:00:00.000Z',
          'updated_at': '2026-07-10T08:00:00.000Z',
        };
      });
      supabase.registerHandler('transform_to_organization', (params) async {
        expect(params?['p_tenant_id'], tenantId);
        expect(params?['p_actor_id'], actorId);
        expect(params?['p_partner_id'], 'p-person-1');
        expect(params?['p_expected_version'], 2);
        final profile = params?['p_organization_profile'] as Map<String, dynamic>;
        expect(profile['organization_name'], 'Công ty TNHH An Phát');
        expect(profile['phone'], '02838225511');
        return [
          {'partner_id': 'p-person-1'},
        ];
      });

      final result = await module.executeCommandAsync(
        TransformPersonToOrganizationCommand(
          tenantId: tenantId,
          actorId: actorId,
          partnerId: 'p-person-1',
          expectedVersion: 2,
          organizationProfile: const OrganizationProfileInput(
            organizationType: OrganizationType.company,
            organizationName: 'Công ty TNHH An Phát',
            phone: '02838225511',
            taxCode: '0316789012',
          ),
        ),
      );

      expect(result.partnerId, 'p-person-1');
      expect(
        supabase.calls.map((c) => c.functionName),
        ['get_partner_detail', 'transform_to_organization'],
      );
    });

    test('version mismatch surfaces STATE_CHANGED before write RPC', () async {
      supabase.registerHandler('get_partner_detail', (_) async {
        return <String, dynamic>{
          'partner_id': 'p-person-1',
          'partner_type': 'person',
          'status': 'active',
          'display_name': 'Nguyễn Văn A',
          'roles': <String>['customer'],
          'available_actions': <String>['transform'],
          'expected_version': 5,
          'person_profile': <String, dynamic>{
            'full_name': 'Nguyễn Văn A',
            'phone': '0901234567',
          },
          'organization_profile': null,
          'contacts': <dynamic>[],
        };
      });

      await expectLater(
        module.executeCommandAsync(
          TransformPersonToOrganizationCommand(
            tenantId: tenantId,
            actorId: actorId,
            partnerId: 'p-person-1',
            expectedVersion: 2,
            organizationProfile: const OrganizationProfileInput(
              organizationType: OrganizationType.company,
              organizationName: 'Công ty A',
              phone: '02838225511',
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
  });
}
