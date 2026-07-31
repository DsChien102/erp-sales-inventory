import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_infrastructure/src/domain/invitation/supabase_tenant_invitation_command_gateway.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'support/fake_iam_rpc_supabase.dart';

void main() {
  group('SupabaseTenantInvitationCommandGateway S7/S9', () {
    test('create_tenant_invitation params and detail mapping', () async {
      final supabase = FakeIamRpcSupabase()
        ..registerHandler(
          'create_tenant_invitation',
          (_) async => _detailPayload(deliveryStatus: 'queued'),
        );
      final gateway = _gateway(supabase);

      final detail = await gateway.createInvitation(
        tenantId: 't1',
        inviteeEmail: 'a@example.com',
        initialRoleId: 'role-1',
        idempotencyKey: 'idem-1',
      );

      expect(supabase.calls.single.functionName, 'create_tenant_invitation');
      expect(supabase.calls.single.params, {
        'p_tenant_id': 't1',
        'p_invitee_email': 'a@example.com',
        'p_initial_role_id': 'role-1',
        'p_idempotency_key': 'idem-1',
      });
      expect(detail.invitationId, 'inv-1');
      expect(detail.deliveryStatus, 'queued');
      expect(detail.deliveryCorrelationId, 'corr-1');
      expect(detail.lastSentAt!.toUtc().toIso8601String(), '2026-07-02T00:00:00.000Z');
    });

    test('resend and revoke params + UTC terminal timestamps', () async {
      final supabase = FakeIamRpcSupabase()
        ..registerHandler(
          'resend_tenant_invitation',
          (_) async => _detailPayload(deliveryStatus: 'queued', version: 2),
        )
        ..registerHandler(
          'revoke_tenant_invitation',
          (_) async => _detailPayload(
            status: 'revoked',
            version: 3,
            revokedAt: '2026-07-05T12:00:00Z',
            lastSentAt: '2026-07-02T00:00:00Z',
          ),
        );
      final gateway = _gateway(supabase);

      await gateway.resendInvitation(
        tenantId: 't1',
        invitationId: 'inv-1',
        expectedVersion: 1,
        idempotencyKey: 'resend-1',
      );
      expect(supabase.calls[0].functionName, 'resend_tenant_invitation');
      expect(supabase.calls[0].params, {
        'p_tenant_id': 't1',
        'p_invitation_id': 'inv-1',
        'p_expected_version': 1,
        'p_idempotency_key': 'resend-1',
      });

      final revoked = await gateway.revokeInvitation(
        tenantId: 't1',
        invitationId: 'inv-1',
        expectedVersion: 2,
        reason: 'no longer needed',
        idempotencyKey: 'revoke-1',
      );
      expect(supabase.calls[1].functionName, 'revoke_tenant_invitation');
      expect(supabase.calls[1].params, {
        'p_tenant_id': 't1',
        'p_invitation_id': 'inv-1',
        'p_expected_version': 2,
        'p_reason': 'no longer needed',
        'p_idempotency_key': 'revoke-1',
      });
      expect(revoked.status, 'revoked');
      expect(revoked.revokedAt!.toUtc().toIso8601String(), '2026-07-05T12:00:00.000Z');
      expect(revoked.lastSentAt, isNotNull);
      expect(revoked.declinedAt, isNull);
    });

    test('maps blocked codes stably', () async {
      Future<void> expectCode(String rpc, String raised, String expected) async {
        final supabase = FakeIamRpcSupabase()
          ..registerHandler(rpc, (_) async => throw RpcException(raised));
        final gateway = _gateway(supabase);

        Future<void> call() {
          return switch (rpc) {
            'resend_tenant_invitation' => gateway.resendInvitation(
                tenantId: 't1',
                invitationId: 'inv-1',
                expectedVersion: 1,
                idempotencyKey: 'k',
              ),
            'revoke_tenant_invitation' => gateway.revokeInvitation(
                tenantId: 't1',
                invitationId: 'inv-1',
                expectedVersion: 1,
                reason: 'r',
                idempotencyKey: 'k',
              ),
            _ => gateway.createInvitation(
                tenantId: 't1',
                inviteeEmail: 'a@example.com',
                initialRoleId: 'role-1',
                idempotencyKey: 'k',
              ),
          };
        }

        await expectLater(
          call,
          throwsA(
            isA<IamBlockedException>().having((e) => e.code, 'code', expected),
          ),
        );
      }

      await expectCode(
        'resend_tenant_invitation',
        'STATE_CHANGED',
        IamBlockedCodes.stateChanged,
      );
      await expectCode(
        'revoke_tenant_invitation',
        'INVITATION_ALREADY_USED',
        IamBlockedCodes.invitationAlreadyUsed,
      );
      await expectCode(
        'create_tenant_invitation',
        'RESOURCE_NOT_FOUND',
        IamBlockedCodes.resourceNotFound,
      );
      await expectCode(
        'resend_tenant_invitation',
        'IDEMPOTENCY_CONFLICT',
        IamBlockedCodes.idempotencyConflict,
      );
    });
  });
}

Map<String, dynamic> _detailPayload({
  String status = 'pending',
  String deliveryStatus = 'queued',
  int version = 1,
  String? revokedAt,
  String? lastSentAt = '2026-07-02T00:00:00Z',
}) {
  return {
    'invitation_id': 'inv-1',
    'invitee_email': 'a@example.com',
    'initial_role_id': 'role-1',
    'initial_role_label': 'Staff',
    'status': status,
    'expires_at': '2026-07-10T00:00:00Z',
    'delivery_status': deliveryStatus,
    'delivery_correlation_id': 'corr-1',
    'version': version,
    'created_at': '2026-07-01T00:00:00Z',
    'created_by': 'user-1',
    'last_sent_at': lastSentAt,
    'revoked_at': revokedAt,
    'declined_at': null,
  };
}

SupabaseTenantInvitationCommandGateway _gateway(FakeIamRpcSupabase supabase) {
  return SupabaseTenantInvitationCommandGateway(
    rpcClient: SupabaseSchemaRpcClient(
      supabase: supabase,
      schema: 'iam',
      mapError: (error, [stackTrace]) =>
          error is RpcException ? error : RpcException(error.toString()),
    ),
  );
}
