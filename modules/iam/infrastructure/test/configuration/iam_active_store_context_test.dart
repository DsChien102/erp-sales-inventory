import 'dart:async';

import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';
import 'package:vet45_iam_infrastructure/src/configuration/session/iam_active_store_context.dart';
import 'package:vet45_iam_infrastructure/src/domain/access/supabase_iam_access_gateway.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

final class _FakeSupabaseClient implements SupabaseClient {
  _FakeSupabaseClient(this._response);

  final Map<String, dynamic> _response;
  String? functionName;

  @override
  SupabaseQuerySchema schema(String schema) => _FakeQuerySchema(this);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final class _FakeQuerySchema implements SupabaseQuerySchema {
  _FakeQuerySchema(this._client);

  final _FakeSupabaseClient _client;

  @override
  PostgrestFilterBuilder<T> rpc<T>(
    String fn, {
    Map<String, dynamic>? params,
    bool get = false,
  }) => _FakePostgrestRpc<T>(_client, fn);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final class _FakePostgrestRpc<T> implements PostgrestFilterBuilder<T> {
  _FakePostgrestRpc(this._client, this._functionName);

  final _FakeSupabaseClient _client;
  final String _functionName;

  @override
  Stream<T> asStream() => throw UnsupportedError('stream not supported');

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) {
    _client.functionName = _functionName;
    return Future<T>.value(_client._response as T).then(
      onValue,
      onError: onError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  test('session requires the active store resolved by IAM', () async {
    final session = IamSession();
    session.apply(
      const PrincipalAccessDto(
        userId: 'user-1',
        tenantId: 'tenant-1',
        activeStoreId: 'store-1',
        role: 'member',
        isOwner: false,
        permissions: <String>[],
      ),
    );

    expect(session.activeStoreId, 'store-1');
    expect(await session.requireActiveStoreId(), 'store-1');
    expect(session.toDto().activeStoreId, 'store-1');
  });

  test('missing active store fails closed', () async {
    final session = IamSession();
    session.apply(
      const PrincipalAccessDto(
        userId: 'user-1',
        tenantId: 'tenant-1',
        activeStoreId: null,
        role: 'member',
        isOwner: false,
        permissions: <String>[],
      ),
    );

    await expectLater(
      session.requireActiveStoreId(),
      throwsA(isA<ApplicationException>()),
    );
  });

  test('clearing the session removes its active store', () {
    final session = IamSession();
    session.apply(
      const PrincipalAccessDto(
        userId: 'user-1',
        tenantId: 'tenant-1',
        activeStoreId: 'store-1',
        role: 'member',
        isOwner: false,
        permissions: <String>[],
      ),
    );

    session.clear();

    expect(session.activeStoreId, isNull);
    expect(session.toDto().activeStoreId, isNull);
  });

  test('access gateway maps active-store snapshot from IAM session context', () async {
    final supabase = _FakeSupabaseClient({
      'user_id': 'user-1',
      'tenant_id': 'tenant-1',
      'active_store_id': 'store-1',
      'active_store_code': 'HCM-01',
      'active_store_display_name': 'Chi nhánh Hồ Chí Minh',
      'role': 'member',
      'permissions': <String>[],
    });
    final gateway = SupabaseIamAccessGateway(
      rpcClient: SupabaseSchemaRpcClient(
        supabase: supabase,
        schema: 'iam',
        mapError: (error, [stackTrace]) => RpcException(error.toString()),
      ),
    );

    final context = await gateway.getSessionContext();

    expect(supabase.functionName, 'get_session_context');
    expect(context?.activeStoreId, 'store-1');
    expect(context?.activeStoreCode, 'HCM-01');
    expect(context?.activeStoreDisplayName, 'Chi nhánh Hồ Chí Minh');
  });

  test('active store context refreshes session when store is missing', () async {
    final session = IamSession();
    session.apply(
      const PrincipalAccessDto(
        userId: 'user-1',
        tenantId: 'tenant-1',
        activeStoreId: null,
        role: 'store_owner',
        isOwner: true,
        permissions: <String>[],
      ),
    );

    final context = IamActiveStoreContext(
      session: session,
      accessGateway: _RefreshingAccessGateway(),
    );

    expect(await context.requireActiveStoreId(), 'store-refreshed');
    expect(session.activeStoreId, 'store-refreshed');
  });
}

final class _RefreshingAccessGateway implements IIamAccessGateway {
  @override
  Future<void> assignMemberRole({
    required String tenantId,
    required String userId,
    required String role,
  }) async {}

  @override
  Future<PrincipalAccessDto?> getSessionContext({String? tenantId}) async {
    return const PrincipalAccessDto(
      userId: 'user-1',
      tenantId: 'tenant-1',
      activeStoreId: 'store-refreshed',
      role: 'store_owner',
      isOwner: true,
      permissions: <String>[],
    );
  }

  @override
  Future<TenantContextDto> getValidatedTenantContext({
    String? sessionTenantId,
  }) async => throw UnimplementedError();

  @override
  Future<bool> hasPermission({
    required String tenantId,
    required String permission,
  }) async => false;

  @override
  Future<bool> isMember(String tenantId) async => false;

  @override
  Future<List<AccessibleTenantDto>> listAccessibleTenants() async => const [];

  @override
  Future<CursorPageDto<TenantMemberDto>> listTenantMembers({
    required String tenantId,
    String? search,
    String? status,
    String? cursor,
    int limit = 20,
  }) async => const CursorPageDto<TenantMemberDto>(items: []);

  @override
  Future<List<TenantMembershipDto>> listUserTenants() async => const [];

  @override
  Future<TenantContextDto> switchTenantContext({
    required String targetTenantId,
  }) async => throw UnimplementedError();
}
