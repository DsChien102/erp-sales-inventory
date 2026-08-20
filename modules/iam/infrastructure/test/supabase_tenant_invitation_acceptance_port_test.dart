import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_iam_infrastructure/src/domain/invitation/supabase_tenant_invitation_acceptance_port.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'support/fake_iam_rpc_supabase.dart';

void main() {
  group('SupabaseTenantInvitationAcceptancePort', () {
    test('inspect_invitation_token name/params/mapping', () async {
      final supabase = FakeIamRpcSupabase()
        ..registerHandler(
          'inspect_invitation_token',
          (_) async => {
            'tenant_id': 't1',
            'tenant_name': 'Clinic',
            'invitee_email': 'a@example.com',
            'initial_role_id': 'role-1',
            'initial_role_label': 'Staff',
            'expires_at': '2026-07-10T00:00:00Z',
            'account_exists': true,
            'given_name': 'Chiến',
            'family_name': 'Đỗ Sỹ',
            'phone': '0901234567',
          },
        );
      final port = _port(supabase);

      final inspection = await port.inspectToken('tok-1');
      expect(supabase.calls.single.functionName, 'inspect_invitation_token');
      expect(supabase.calls.single.params, {'p_token': 'tok-1'});
      expect(inspection.tenantId, 't1');
      expect(inspection.accountExists, isTrue);
      expect(inspection.givenName, 'Chiến');
      expect(inspection.familyName, 'Đỗ Sỹ');
      expect(inspection.phone, '0901234567');
      expect(inspection.expiresAt.toUtc().toIso8601String(), '2026-07-10T00:00:00.000Z');
    });

    test('accept and decline mapping', () async {
      final supabase = FakeIamRpcSupabase()
        ..registerHandler(
          'accept_invitation',
          (_) async => {
            'membership_id': 'mem-1',
            'tenant_id': 't1',
            'user_id': 'user-1',
            'role': 'staff',
            'is_owner': false,
            'is_sole_owner': false,
            'status': 'active',
            'version': 1,
            'joined_at': '2026-07-01T00:00:00Z',
            'status_changed_at': null,
            'removed_at': null,
          },
        )
        ..registerHandler(
          'decline_invitation',
          (_) async => {
            'invitation_id': 'inv-1',
            'invitee_email': 'a@example.com',
            'initial_role_id': 'role-1',
            'initial_role_label': 'Staff',
            'status': 'declined',
            'expires_at': '2026-07-10T00:00:00Z',
            'delivery_status': 'queued',
            'delivery_correlation_id': 'corr-1',
            'version': 2,
            'created_at': '2026-07-01T00:00:00Z',
            'created_by': 'user-0',
            'last_sent_at': '2026-07-01T00:00:00Z',
            'revoked_at': null,
            'declined_at': '2026-07-02T00:00:00Z',
          },
        );
      final port = _port(supabase);

      final member = await port.acceptInvitation(
        token: 'tok-1',
        idempotencyKey: 'idem-1',
      );
      expect(supabase.calls[0].functionName, 'accept_invitation');
      expect(supabase.calls[0].params, {
        'p_token': 'tok-1',
        'p_idempotency_key': 'idem-1',
      });
      expect(member.membershipId, 'mem-1');
      expect(member.status, MembershipStatus.active);

      final declined = await port.declineInvitation(
        token: 'tok-1',
        idempotencyKey: 'idem-2',
      );
      expect(supabase.calls[1].functionName, 'decline_invitation');
      expect(declined.status, 'declined');
      expect(declined.declinedAt, isNotNull);
    });

    test('maps invitation blocked codes', () async {
      Future<void> expectCode(String rpc, String raised, String code) async {
        final supabase = FakeIamRpcSupabase()
          ..registerHandler(rpc, (_) async => throw RpcException(raised));
        final port = _port(supabase);
        Future<void> call() {
          return switch (rpc) {
            'accept_invitation' => port.acceptInvitation(
              token: 't',
              idempotencyKey: 'k',
            ),
            'decline_invitation' => port.declineInvitation(
              token: 't',
              idempotencyKey: 'k',
            ),
            _ => port.inspectToken('t'),
          };
        }

        await expectLater(
          call,
          throwsA(
            isA<IamBlockedException>().having((e) => e.code, 'code', code),
          ),
        );
      }

      await expectCode(
        'inspect_invitation_token',
        'INVITATION_TOKEN_INVALID',
        IamBlockedCodes.invitationTokenInvalid,
      );
      await expectCode(
        'accept_invitation',
        'INVITATION_EXPIRED',
        IamBlockedCodes.invitationExpired,
      );
      await expectCode(
        'accept_invitation',
        'INVITATION_REVOKED',
        IamBlockedCodes.invitationRevoked,
      );
      await expectCode(
        'accept_invitation',
        'INVITATION_EMAIL_MISMATCH',
        IamBlockedCodes.invitationEmailMismatch,
      );
      await expectCode(
        'accept_invitation',
        'TENANT_SUSPENDED',
        IamBlockedCodes.tenantSuspended,
      );
    });
  });
}

SupabaseTenantInvitationAcceptancePort _port(FakeIamRpcSupabase supabase) {
  return SupabaseTenantInvitationAcceptancePort(
    rpcClient: SupabaseSchemaRpcClient(
      supabase: supabase,
      schema: 'iam',
      mapError: (error, [stackTrace]) =>
          error is RpcException ? error : RpcException(error.toString()),
    ),
  );
}
