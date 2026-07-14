import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_infrastructure/infrastructure.dart';

import 'support/fake_partner_rpc_supabase.dart';

void main() {
  const tenantId = 'tenant-1';
  const actorId = 'user-1';
  const partnerId = 'p-1';

  Map<String, dynamic> detailRow({required int expectedVersion}) {
    return <String, dynamic>{
      'partner_id': partnerId,
      'partner_type': 'organization',
      'status': 'active',
      'display_name': 'Công ty ABC',
      'roles': <String>['customer'],
      'available_actions': <String>['delete', 'deactivate'],
      'expected_version': expectedVersion,
      'person_profile': null,
      'organization_profile': <String, dynamic>{
        'organization_type': 'company',
        'organization_name': 'Công ty ABC',
        'phone': '02838225511',
      },
      'contacts': <dynamic>[],
      'created_at': '2026-07-01T10:00:00.000Z',
      'updated_at': '2026-07-10T08:00:00.000Z',
    };
  }

  group('e2e_e02_u02_fr01_01 partner soft delete integration', () {
    late FakePartnerRpcSupabase supabase;
    late IPartnerModule module;

    setUp(() {
      supabase = FakePartnerRpcSupabase();
      module = PartnerStartup.initializeForTesting(supabase: supabase);
    });

    test('eligibility query returns eligible via RPC', () async {
      supabase.registerHandler('check_delete_eligibility', (params) async {
        expect(params?['p_tenant_id'], tenantId);
        expect(params?['p_partner_id'], partnerId);
        return [
          {'eligible': true, 'reason': null},
        ];
      });

      final result = await module.executeQueryAsync(
        CheckDeleteEligibilityQuery(
          tenantId: tenantId,
          partnerId: partnerId,
        ),
      );

      expect(result.eligible, isTrue);
      expect(result.reason, isNull);
      expect(
        supabase.calls.map((c) => c.functionName),
        ['check_delete_eligibility'],
      );
    });

    test('soft delete succeeds when eligible', () async {
      supabase.registerHandler('get_partner_detail', (_) async {
        return detailRow(expectedVersion: 3);
      });
      supabase.registerHandler('check_delete_eligibility', (_) async {
        return [
          {'eligible': true, 'reason': null},
        ];
      });
      supabase.registerHandler('soft_delete_partner', (params) async {
        expect(params?['p_tenant_id'], tenantId);
        expect(params?['p_actor_id'], actorId);
        expect(params?['p_partner_id'], partnerId);
        expect(params?['p_expected_version'], 3);
        expect(params?['p_reason'], 'Tạo nhầm');
        return [
          {
            'partner_id': partnerId,
            'status': 'deleted',
            'expected_version': 4,
          },
        ];
      });

      final result = await module.executeCommandAsync(
        SoftDeletePartnerCommand(
          tenantId: tenantId,
          actorId: actorId,
          partnerId: partnerId,
          reason: 'Tạo nhầm',
          expectedVersion: 3,
        ),
      );

      expect(result.partnerId, partnerId);
      expect(result.expectedVersion, 4);
      expect(
        supabase.calls.map((c) => c.functionName),
        [
          'get_partner_detail',
          'check_delete_eligibility',
          'soft_delete_partner',
        ],
      );
    });

    test('HAS_TRANSACTIONS blocks soft delete before write RPC', () async {
      supabase.registerHandler('get_partner_detail', (_) async {
        return detailRow(expectedVersion: 1);
      });
      supabase.registerHandler('check_delete_eligibility', (_) async {
        return [
          {'eligible': false, 'reason': 'HAS_TRANSACTIONS'},
        ];
      });

      await expectLater(
        module.executeCommandAsync(
          SoftDeletePartnerCommand(
            tenantId: tenantId,
            actorId: actorId,
            partnerId: partnerId,
            expectedVersion: 1,
          ),
        ),
        throwsA(isA<Exception>()),
      );

      expect(
        supabase.calls.map((c) => c.functionName),
        ['get_partner_detail', 'check_delete_eligibility'],
      );
      expect(
        supabase.calls.any((c) => c.functionName == 'soft_delete_partner'),
        isFalse,
      );
    });
  });
}
