import 'package:vet45_adapters/vet45_adapters.dart';

/// RPC surface used by partner messaging processors (testable via fakes).
abstract interface class PartnerSchemaRpc {
  Future<List<Map<String, dynamic>>> callList(
    String functionName, {
    Map<String, dynamic>? params,
  });

  Future<T> callScalar<T>(
    String functionName, {
    Map<String, dynamic>? params,
  });
}

final class SupabasePartnerSchemaRpc implements PartnerSchemaRpc {
  const SupabasePartnerSchemaRpc(this._client);

  final SupabaseSchemaRpcClient _client;

  @override
  Future<List<Map<String, dynamic>>> callList(
    String functionName, {
    Map<String, dynamic>? params,
  }) {
    return _client.callList(functionName, params: params);
  }

  @override
  Future<T> callScalar<T>(
    String functionName, {
    Map<String, dynamic>? params,
  }) async {
    final result = await _client.callScalar<T>(functionName, params: params);
    return result as T;
  }
}
