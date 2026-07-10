import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_infrastructure/infrastructure.dart';

import 'support/fake_partner_rpc_supabase.dart';

void main() {
  const tenantId = 'tenant-1';
  const actorId = 'user-1';
  const partnerId = 'p-1';

  Map<String, dynamic> detailRow({
    required String status,
    required int expectedVersion,
  }) {
    return <String, dynamic>{
      'partner_id': partnerId,
      'partner_type': 'person',
      'status': status,
      'display_name': 'Nguyễn Văn A',
      'roles': <String>['customer'],
      'available_actions': <String>['deactivate', 'reactivate', 'delete'],
      'expected_version': expectedVersion,
      'person_profile': <String, dynamic>{
        'full_name': 'Nguyễn Văn A',
        'phone': '0901234567',
      },
      'organization_profile': null,
      'contacts': <dynamic>[],
      'created_at': '2026-07-01T10:00:00.000Z',
      'updated_at': '2026-07-10T08:00:00.000Z',
    };
  }

  group('e2e_e02_u01_fr01_01 partner deactivate / reactivate integration', () {
    late FakePartnerRpcSupabase supabase;
    late IPartnerModule module;

    setUp(() {
      supabase = FakePartnerRpcSupabase();
      module = PartnerStartup.initializeForTesting(supabase: supabase);
    });

    test('deactivate succeeds via mediator and RPC', () async {
      supabase.registerHandler('get_partner_detail', (_) async {
        return detailRow(status: 'active', expectedVersion: 2);
      });
      supabase.registerHandler('deactivate_partner', (params) async {
        expect(params?['p_tenant_id'], tenantId);
        expect(params?['p_actor_id'], actorId);
        expect(params?['p_partner_id'], partnerId);
        expect(params?['p_expected_version'], 2);
        expect(params?['p_reason'], 'Không còn giao dịch');
        return [
          {
            'partner_id': partnerId,
            'status': 'inactive',
            'expected_version': 3,
          },
        ];
      });

      final result = await module.executeCommandAsync(
        DeactivatePartnerCommand(
          tenantId: tenantId,
          actorId: actorId,
          partnerId: partnerId,
          reason: 'Không còn giao dịch',
          expectedVersion: 2,
        ),
      );

      expect(result.partnerId, partnerId);
      expect(result.expectedVersion, 3);
      expect(
        supabase.calls.map((c) => c.functionName),
        ['get_partner_detail', 'deactivate_partner'],
      );
    });

    test('reactivate succeeds via mediator and RPC', () async {
      supabase.registerHandler('get_partner_detail', (_) async {
        return detailRow(status: 'inactive', expectedVersion: 4);
      });
      supabase.registerHandler('reactivate_partner', (params) async {
        expect(params?['p_partner_id'], partnerId);
        expect(params?['p_expected_version'], 4);
        return [
          {
            'partner_id': partnerId,
            'status': 'active',
            'expected_version': 5,
          },
        ];
      });

      final result = await module.executeCommandAsync(
        ReactivatePartnerCommand(
          tenantId: tenantId,
          actorId: actorId,
          partnerId: partnerId,
          expectedVersion: 4,
        ),
      );

      expect(result.partnerId, partnerId);
      expect(result.expectedVersion, 5);
      expect(
        supabase.calls.map((c) => c.functionName),
        ['get_partner_detail', 'reactivate_partner'],
      );
    });

    test('version mismatch surfaces STATE_CHANGED before write RPC', () async {
      supabase.registerHandler('get_partner_detail', (_) async {
        return detailRow(status: 'active', expectedVersion: 9);
      });

      await expectLater(
        module.executeCommandAsync(
          DeactivatePartnerCommand(
            tenantId: tenantId,
            actorId: actorId,
            partnerId: partnerId,
            expectedVersion: 2,
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
