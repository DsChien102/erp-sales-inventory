import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_infrastructure/src/domain/platform/supabase_platform_admin_gateway.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'support/fake_iam_rpc_supabase.dart';

void main() {
  test('createTenantOnboarding calls tenant RPC with resolved owner user id', () async {
    final supabase = FakeIamRpcSupabase();
    supabase.registerHandler('create_tenant_onboarding', (params) async {
      expect(params?['p_owner_user_id'], 'resolved-user-id');
      expect(params?['p_org_name'], 'Org Moi');
      expect(params?['p_org_display_name'], 'Org Display');
      expect(params?['p_org_contact_email'], 'contact@example.com');
      expect(params?['p_org_contact_phone'], '0909123456');
      expect(params?['p_org_contact_address_text'], '123 Main');
      expect(params?['p_org_province_code'], 'Thành phố Hà Nội');
      expect(params?['p_org_commune_code'], 'Phường Ba Đình');
      expect(params?['p_org_legal_name'], 'Org Legal Co');
      expect(params?['p_org_tax_code'], '0123456789');
      expect(params?['p_idempotency_key'], 'idem-1');
      expect(params?['p_correlation_id'], 'corr-1');
      expect(params?['p_is_new_user'], true);
      return {
        'tenant_id': 'tenant-1',
        'owner_membership_id': 'membership-1',
        'owner_user_id': 'resolved-user-id',
        'tenant_status': 'provisioning',
        'correlation_id': 'corr-1',
        'is_new_user': true,
      };
    });
    final gateway = SupabasePlatformAdminGateway(
      rpcClient: SupabaseSchemaRpcClient(
        supabase: supabase,
        schema: 'iam',
        mapError: (error, [stackTrace]) => RpcException(error.toString()),
      ),
    );

    final result = await gateway.createTenantOnboarding(
      ownerUserId: 'resolved-user-id',
      isNewUser: true,
      organizationName: 'Org Moi',
      organizationDisplayName: 'Org Display',
      contactEmail: 'contact@example.com',
      contactPhone: '0909123456',
      contactAddressText: '123 Main',
      provinceCode: 'Thành phố Hà Nội',
      communeCode: 'Phường Ba Đình',
      legalName: 'Org Legal Co',
      taxCode: '0123456789',
      idempotencyKey: 'idem-1',
      correlationId: 'corr-1',
    );

    expect(result.ownerUserId, 'resolved-user-id');
    expect(result.isNewUser, isTrue);
    expect(supabase.calls.single.functionName, 'create_tenant_onboarding');
  });
}
