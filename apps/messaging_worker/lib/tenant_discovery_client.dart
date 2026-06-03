import 'package:supabase/supabase.dart';

/// Tenant row returned by platform discovery RPC.
final class PendingTenant {
  const PendingTenant({
    required this.tenantId,
    required this.oldestCreatedAt,
  });

  final String tenantId;
  final DateTime oldestCreatedAt;

  factory PendingTenant.fromJson(Map<String, dynamic> json) {
    return PendingTenant(
      tenantId: json['tenant_id'] as String,
      oldestCreatedAt: DateTime.parse(json['oldest_created_at'] as String),
    );
  }
}

abstract interface class ITenantDiscoveryClient {
  Future<List<PendingTenant>> listTenantsWithPendingMessaging({required int limit});
}

final class SupabaseTenantDiscoveryClient implements ITenantDiscoveryClient {
  SupabaseTenantDiscoveryClient(this._supabase);

  final SupabaseClient _supabase;

  @override
  Future<List<PendingTenant>> listTenantsWithPendingMessaging({
    required int limit,
  }) async {
    final result = await _supabase
        .schema('platform')
        .rpc(
          'list_tenants_with_pending_messaging',
          params: {'p_limit': limit},
        );

    if (result == null) {
      return const [];
    }

    if (result is! List<dynamic>) {
      return const [];
    }

    return result
        .map((row) => PendingTenant.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }
}
