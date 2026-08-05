import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_infrastructure/src/adapters/identity/supabase_platform_identity_provisioning_adapter.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'support/fake_iam_rpc_supabase.dart';

void main() {
  SupabaseSchemaRpcClient rpcClient(FakeIamRpcSupabase supabase) {
    return SupabaseSchemaRpcClient(
      supabase: supabase,
      schema: 'iam',
      mapError: (error, [stackTrace]) => RpcException(error.toString()),
    );
  }

  test('existing owner resolves locally without provisioning RPC', () async {
    final supabase = FakeIamRpcSupabase();
    final adapter = SupabasePlatformIdentityProvisioningAdapter(
      rpcClient: rpcClient(supabase),
    );

    final result = await adapter.resolveOrCreateOwnerForOnboarding(
      owner: const OnboardingOwnerInput.existing('existing-user-id'),
      idempotencyKey: 'idem-existing',
      correlationId: 'corr-existing',
    );

    expect(result.ownerUserId, 'existing-user-id');
    expect(result.isNewUser, isFalse);
    expect(result.status, 'active');
    expect(result.activationDeliveryRequested, isFalse);
    expect(supabase.calls, isEmpty);
  });

  test('new owner calls resolve/create onboarding identity RPC', () async {
    final supabase = FakeIamRpcSupabase();
    supabase.registerHandler('resolve_or_create_platform_user_for_onboarding', (
      params,
    ) async {
      expect(params?['p_email'], 'new@example.com');
      expect(params?['p_first_name'], 'An');
      expect(params?['p_last_name'], 'Nguyen');
      expect(params?['p_phone'], '0909123456');
      expect(params?['p_idempotency_key'], 'idem-new');
      expect(params?['p_correlation_id'], 'corr-new');
      return {
        'owner_user_id': 'resolved-user-id',
        'is_new_user': true,
        'status': 'pending_activation',
        'activation_delivery_requested': true,
      };
    });
    final adapter = SupabasePlatformIdentityProvisioningAdapter(
      rpcClient: rpcClient(supabase),
    );

    final result = await adapter.resolveOrCreateOwnerForOnboarding(
      owner: const OnboardingOwnerInput.newUser(
        lastName: ' Nguyen ',
        firstName: ' An ',
        email: ' NEW@example.com ',
        phone: ' 0909123456 ',
      ),
      idempotencyKey: 'idem-new',
      correlationId: 'corr-new',
    );

    expect(result.ownerUserId, 'resolved-user-id');
    expect(result.isNewUser, isTrue);
    expect(result.status, 'pending_activation');
    expect(result.activationDeliveryRequested, isTrue);
    expect(
      supabase.calls.single.functionName,
      'resolve_or_create_platform_user_for_onboarding',
    );
  });
}
