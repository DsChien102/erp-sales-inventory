import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_infrastructure/src/domain/invitation/supabase_tenant_invitation_read_port.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'support/fake_iam_rpc_supabase.dart';

void main() {
  group('SupabaseTenantInvitationReadPort', () {
    test('list sends exact params and maps page + next_cursor', () async {
      final supabase = FakeIamRpcSupabase()
        ..registerHandler(
          'list_tenant_invitations',
          (_) async => {
            'items': [
              {
                'invitation_id': 'inv-1',
                'invitee_email': 'a@example.com',
                'initial_role_id': 'role-1',
                'initial_role_label': 'Staff',
                'status': 'expired',
                'expires_at': '2026-07-01T00:00:00Z',
                'delivery_status': 'queued',
                'delivery_correlation_id': 'corr-1',
                'version': 2,
              },
            ],
            'next_cursor': 'c1',
          },
        );
      final port = _port(supabase);

      final page = await port.listInvitations(
        tenantId: 't1',
        search: 'a@',
        status: 'expired',
        cursor: 'prev',
        limit: 15,
      );

      expect(supabase.calls.single.functionName, 'list_tenant_invitations');
      expect(supabase.calls.single.params, {
        'p_tenant_id': 't1',
        'p_search': 'a@',
        'p_status': 'expired',
        'p_cursor': 'prev',
        'p_limit': 15,
      });
      expect(page.nextCursor, 'c1');
      expect(page.items.single.status, 'expired');
      expect(page.items.single.inviteeEmail, 'a@example.com');
      expect(page.items.single.deliveryCorrelationId, 'corr-1');
    });

    test('get maps detail timestamps; empty map returns null', () async {
      final supabase = FakeIamRpcSupabase()
        ..registerHandler(
          'get_tenant_invitation',
          (params) async {
            if (params?['p_invitation_id'] == 'missing') {
              return <String, dynamic>{};
            }
            return {
              'invitation_id': 'inv-1',
              'invitee_email': 'a@example.com',
              'initial_role_id': 'role-1',
              'initial_role_label': 'Staff',
              'status': 'revoked',
              'expires_at': '2026-07-10T00:00:00Z',
              'delivery_status': 'sent',
              'delivery_correlation_id': 'corr-1',
              'version': 3,
              'created_at': '2026-07-01T00:00:00Z',
              'created_by': 'user-1',
              'last_sent_at': '2026-07-02T00:00:00Z',
              'revoked_at': '2026-07-03T00:00:00Z',
              'declined_at': null,
            };
          },
        );
      final port = _port(supabase);

      final missing = await port.getInvitation(
        tenantId: 't1',
        invitationId: 'missing',
      );
      expect(missing, isNull);

      final detail = await port.getInvitation(
        tenantId: 't1',
        invitationId: 'inv-1',
      );
      expect(detail, isNotNull);
      expect(detail!.createdBy, 'user-1');
      expect(detail.lastSentAt!.toUtc().toIso8601String(), '2026-07-02T00:00:00.000Z');
      expect(detail.revokedAt!.toUtc().toIso8601String(), '2026-07-03T00:00:00.000Z');
      expect(supabase.calls.last.params, {
        'p_tenant_id': 't1',
        'p_invitation_id': 'inv-1',
      });
    });

    test('maps PERMISSION_DENIED and SYSTEM_ERROR', () async {
      final supabase = FakeIamRpcSupabase()
        ..registerHandler(
          'list_tenant_invitations',
          (_) async => throw RpcException('PERMISSION_DENIED'),
        )
        ..registerHandler(
          'get_tenant_invitation',
          (_) async => throw RpcException('boom'),
        );
      final port = _port(supabase);

      expect(
        () => port.listInvitations(tenantId: 't1'),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.permissionDenied,
          ),
        ),
      );
      expect(
        () => port.getInvitation(tenantId: 't1', invitationId: 'inv-1'),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.systemError,
          ),
        ),
      );
    });
  });
}

SupabaseTenantInvitationReadPort _port(FakeIamRpcSupabase supabase) {
  return SupabaseTenantInvitationReadPort(
    rpcClient: SupabaseSchemaRpcClient(
      supabase: supabase,
      schema: 'iam',
      mapError: (error, [stackTrace]) =>
          error is RpcException ? error : RpcException(error.toString()),
    ),
  );
}
