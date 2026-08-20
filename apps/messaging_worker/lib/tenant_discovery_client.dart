import 'package:supabase/supabase.dart';

/// One pending messaging queue row discovered from platform backlog stats.
final class PendingMessagingWork {
  const PendingMessagingWork({
    required this.tenantId,
    required this.moduleSchema,
    required this.queueType,
    required this.pendingCount,
    required this.oldestCreatedAt,
  });

  final String tenantId;
  final String moduleSchema;
  final String queueType;
  final int pendingCount;
  final DateTime oldestCreatedAt;

  factory PendingMessagingWork.fromJson(Map<String, dynamic> json) {
    return PendingMessagingWork(
      tenantId: json['tenant_id'] as String,
      moduleSchema: json['module_schema'] as String,
      queueType: json['queue_type'] as String,
      pendingCount: (json['pending_count'] as num).toInt(),
      oldestCreatedAt: DateTime.parse(json['oldest_created_at'] as String),
    );
  }
}

abstract interface class ITenantDiscoveryClient {
  Future<List<PendingMessagingWork>> listTenantsWithPendingMessaging({
    required int limit,
    List<String>? modules,
  });
}

final class SupabaseTenantDiscoveryClient implements ITenantDiscoveryClient {
  SupabaseTenantDiscoveryClient(this._supabase);

  final SupabaseClient _supabase;

  @override
  Future<List<PendingMessagingWork>> listTenantsWithPendingMessaging({
    required int limit,
    List<String>? modules,
  }) async {
    final params = <String, dynamic>{'p_limit': limit};
    if (modules != null && modules.isNotEmpty) {
      params['p_modules'] = modules;
    }

    final result = await _supabase
        .schema('platform')
        .rpc(
          'list_tenants_with_pending_messaging',
          params: params,
        );

    if (result == null) {
      return const [];
    }

    if (result is! List<dynamic>) {
      return const [];
    }

    return result
        .map(
          (row) => PendingMessagingWork.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }
}
