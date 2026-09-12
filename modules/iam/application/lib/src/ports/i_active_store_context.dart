/// Resolves the active store authorized by the current IAM session.
abstract interface class IActiveStoreContext {
  String? get activeStoreId;

  Future<String> requireActiveStoreId();
}
