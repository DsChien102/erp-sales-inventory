import 'package:uuid/uuid.dart';

import '../../../core/supabase/supabase_rpc.dart';
import 'models/default_store_warehouse_pair.dart';

class DefaultPairRepository {
  DefaultPairRepository({
    required SupabaseRpc rpc,
    required Future<String> Function() tenantId,
    String? correlationId,
  }) : _rpc = rpc,
       _tenantId = tenantId,
       _correlationId = correlationId ?? const Uuid().v4();

  final SupabaseRpc _rpc;
  final Future<String> Function() _tenantId;
  final String _correlationId;

  /// `inventory.get_default_store_warehouse_pair(p_tenant_id)` → jsonb.
  Future<DefaultStoreWarehousePair> get() async {
    final tenant = await _tenantId();
    final row = await _rpc.call(
      'inventory',
      'get_default_store_warehouse_pair',
      params: {'p_tenant_id': tenant},
    );
    return DefaultStoreWarehousePair.fromJson(
      Map<String, dynamic>.from(row as Map),
    );
  }

  /// `inventory.ensure_default_store_warehouse_pair(p_tenant_id, p_correlation_id)` → jsonb.
  Future<DefaultStoreWarehousePair> ensure() async {
    final tenant = await _tenantId();
    final row = await _rpc.call(
      'inventory',
      'ensure_default_store_warehouse_pair',
      params: {
        'p_tenant_id': tenant,
        'p_correlation_id': _correlationId,
      },
    );
    return DefaultStoreWarehousePair.fromJson(
      Map<String, dynamic>.from(row as Map),
    );
  }
}

