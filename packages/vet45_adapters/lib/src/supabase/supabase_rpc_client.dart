import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'supabase_schema_rpc_client.dart';

/// Supabase implementation of [IRpcClient].
final class SupabaseRpcClient implements IRpcClient {
  SupabaseRpcClient(this._inner);

  final SupabaseSchemaRpcClient _inner;

  @override
  Future<Map<String, dynamic>> call(
    String procedure, {
    Map<String, dynamic>? params,
  }) {
    return _inner.callMap(procedure, params: params);
  }
}
