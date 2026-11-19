/// Checks that the current principal has a permission before command execution.
abstract interface class IPermissionChecker {
  Future<void> require(String permissionCode);
}
