/// RPC transport failure before module-specific error mapping.
final class RpcException implements Exception {
  RpcException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
