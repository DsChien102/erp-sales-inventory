abstract interface class IExecutionContext {
  Future<String> requireUserId();
  Future<String> requireTenantId();
  String get correlationId;
}
