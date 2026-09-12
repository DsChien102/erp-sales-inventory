/// Active store scope for Sales presentation list/cancel flows.
///
/// ERP adapts the IAM session active-store port to this interface.
abstract interface class ISalesActiveStoreContext {
  String? get activeStoreId;

  Future<String> requireActiveStoreId();
}
