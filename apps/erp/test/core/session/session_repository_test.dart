import 'package:erp/core/session/models/accessible_tenant.dart';
import 'package:erp/core/session/models/session_principal.dart';
import 'package:erp/core/session/models/tenant_context.dart';
import 'package:erp/core/session/session_repository.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

class _Rpc extends SupabaseRpc {
  _Rpc()
    : super(
        SupabaseClient(
          'http://127.0.0.1',
          'anon',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  final calls = <({String fn, Map<String, dynamic>? params})>[];
  dynamic next;

  @override
  Future<dynamic> call(
    String schema,
    String fn, {
    Map<String, dynamic>? params = const {},
  }) async {
    calls.add((fn: fn, params: params));
    return next;
  }

  @override
  Future<List<Map<String, dynamic>>> rows(
    String schema,
    String fn, {
    Map<String, dynamic>? params = const {},
  }) async {
    calls.add((fn: fn, params: params));
    final result = next;
    if (result is List) {
      return result.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
    }
    return const [];
  }
}

void main() {
  test('TenantContext.fromJson maps the three statuses and invalidation reasons', () {
    expect(TenantContext.fromJson(const {}).status, TenantContextStatus.none);
    expect(
      TenantContext.fromJson(const {'status': 'valid', 'tenant_id': 't1'}).status,
      TenantContextStatus.valid,
    );
    final invalidated = TenantContext.fromJson(const {
      'status': 'invalidated',
      'invalidation_reason': 'membershipRemoved',
      'blocked_error_code': 'MEMBERSHIP_REMOVED',
    });
    expect(invalidated.status, TenantContextStatus.invalidated);
    expect(invalidated.invalidationReason, TenantContextInvalidationReason.membershipRemoved);
    expect(
      TenantContext.fromJson(const {'invalidation_reason': 'ownershipChanged'}).invalidationReason,
      TenantContextInvalidationReason.ownershipChanged,
    );
    expect(AccessibleTenant.codeFor('org-001'), 'TEN-ORG001');
  });

  test('SessionPrincipal.fromJson keeps optional store ids', () {
    final principal = SessionPrincipal.fromJson(const {
      'user_id': 'u1',
      'tenant_id': 't1',
      'active_store_id': '  ',
      'role': 'staff',
      'permissions': ['tenant.access'],
    });
    expect(principal.activeStoreId, isNull);
    expect(principal.permissions, ['tenant.access']);
  });

  test('getTenantContext omits params when tenantId is null', () async {
    final rpc = _Rpc()..next = const <String, dynamic>{};
    final repository = SessionRepository(rpc: rpc);

    final context = await repository.getTenantContext(null);

    expect(context.status, TenantContextStatus.none);
    expect(rpc.calls.single.fn, 'get_tenant_context');
    expect(rpc.calls.single.params, isNull);
  });
}
