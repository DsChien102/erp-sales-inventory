/// Generic RPC port — infrastructure modules map [RpcException] to domain errors.
abstract interface class IRpcClient {
  Future<Map<String, dynamic>> call(
    String procedure, {
    Map<String, dynamic>? params,
  });
}
